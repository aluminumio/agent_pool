require "db"

module AgentPool
  class AgentPool(T)
    # Pool configuration

    # maximum amount of connections in the pool (Idle + InUse)
    @max_pool_size : Int32
    # maximum amount of idle connections in the pool
    @max_idle_pool_size : Int32
    # seconds to wait before timeout while doing a checkout
    @checkout_timeout : Float64
    # maximum amount of retry attempts to reconnect to the db. See `Pool#retry`
    @retry_attempts : Int32
    # seconds to wait before a retry attempt
    @retry_delay : Float64

    # Pool state

    # total of open connections managed by this pool
    @total = {} of String => Array(T)
    # connections available for checkout
    @idle = {} of String => Set(T)
    # connections waiting to be stablished (they are not in *@idle* nor in *@total*)
    @inflight : Int32

    # Sync state

    # communicate that a connection is available for checkout
    @availability_channel : Channel(Nil)
    # signal how many existing connections are waited for
    @waiting_resource : Int32
    # global pool mutex
    @mutex : Mutex

    def initialize(@max_pool_size = 0, @max_idle_pool_size = 1, @checkout_timeout = 5.0,
                   @retry_attempts = 1, @retry_delay = 0.2, &@factory : String -> T)
      @availability_channel = Channel(Nil).new
      @waiting_resource = 0
      @inflight = 0
      @mutex = Mutex.new
    end

    # close all resources in the pool
    def close : Nil
      @total.each &.map &.close
      @total.clear
      @idle.clear
    end

    record Stats,
      open_connections : Int32,
      idle_connections : Int32,
      in_flight_connections : Int32,
      max_connections : Int32

    # Returns stats of the pool
    def stats
      Stats.new(
        open_connections: @total.values.map(&.size).sum,
        idle_connections: @idle.values.map(&.size).sum,
        in_flight_connections: @inflight,
        max_connections: @max_pool_size,
      )
    end

    def checkout(index) : T
      res = sync do
        resource = nil

        until resource
          resource = if @idle[index]?.nil? || @idle[index].empty?
                       if can_increase_pool?
                         @inflight += 1
                         r = unsync { build_resource(index) }
                         @inflight -= 1
                         r
                       else
                         unsync { wait_for_available }
                         # The wait for available can unlock
                         # multiple fibers waiting for a resource.
                         # Although only one will pick it due to the lock
                         # in the end of the unsync, the pick_available
                         # will return nil
                         pick_available(index)
                       end
                     else
                       pick_available(index)
                     end
        end

        @idle[index].delete resource

        resource
      end

      if res.responds_to?(:before_checkout)
        res.before_checkout
      end
      res
    end

    def checkout(&block : T ->)
      connection = checkout

      begin
        yield connection
      ensure
        release connection
      end
    end

    def release(resource : T, index : String) : Nil
      idle_pushed = false

      return nil unless @total[index]? && @total[index].includes?(resource)

      sync do
        if resource.responds_to?(:closed?) && resource.closed?
          @total[index].delete(resource)
        elsif can_increase_idle_pool
          @idle[index] ||= Set(T).new
          @idle[index] << resource
          if resource.responds_to?(:after_release)
            resource.after_release
          end
          idle_pushed = true
        else
          resource.close
          @total[index].delete(resource)
        end
      end

      if idle_pushed && are_waiting_for_resource?
        @availability_channel.send nil
      end
    end

    # :nodoc:
    # Will retry the block if a `ConnectionLost` exception is thrown.
    # It will try to reuse all of the available connection right away,
    # but if a new connection is needed there is a `retry_delay` seconds delay.
    def retry(index)
      current_available = 0

      sync do
        current_available = @idle[index]?.try(&.size) || 0
        # if the pool hasn't reach the max size, allow 1 attempt
        # to make a new connection if needed without sleeping
        current_available += 1 if can_increase_pool?
      end

      (current_available + @retry_attempts).times do |i|
        begin
          sleep @retry_delay if i >= current_available
          return yield
        rescue e : PoolResourceLost(T)
          # if the connection is lost it will be closed by
          # the exception to release resources
          # we still need to remove it from the known pool.
          # Closed connection will be evicted from statement cache
          # in PoolPreparedStatement#clean_connections
          sync { delete(e.resource, index) }
        rescue e : PoolResourceRefused
          # a ConnectionRefused means a new connection
          # was intended to be created
          # nothing to due but to retry soon
        end
      end
      raise PoolRetryAttemptsExceeded.new
    end

    # :nodoc:
    def each_resource(index)
      sync do
        (!@idle[index].nil ? @idle[index] : [] of T).each do |resource|
          yield resource
        end
      end
    end

    # :nodoc:
    def is_available?(resource : T, index)
      !@idle[index]?.nil? && @idle[index].includes?(resource)
    end

    # :nodoc:
    def delete(resource : T, index)
      !@total[index]?.nil? && @total[index].delete(resource)
      !@idle[index]?.nil? && @idle[index].delete(resource)
    end

    private def build_resource(index) : T
      resource = @factory.call(index)
      @total[index] ||= [] of T
      @total[index] << resource
      @idle[index] ||= Set(T).new
      @idle[index] << resource
      resource
    end

    private def can_increase_pool?
      @max_pool_size == 0 || @total.values.map(&.size).sum + @inflight < @max_pool_size
    end

    private def can_increase_idle_pool
      @idle.values.map(&.size).sum < @max_idle_pool_size
    end

    private def pick_available(index)
      ar = @idle[index]?
      if ar
        return ar.first?
      end
      return nil
    end

    private def wait_for_available
      sync_inc_waiting_resource

      select
      when @availability_channel.receive
        sync_dec_waiting_resource
      when timeout(@checkout_timeout.seconds)
        sync_dec_waiting_resource
        raise DB::PoolTimeout.new("Could not check out a connection in #{@checkout_timeout} seconds")
      end
    end

    private def sync_inc_waiting_resource
      sync { @waiting_resource += 1 }
    end

    private def sync_dec_waiting_resource
      sync { @waiting_resource -= 1 }
    end

    private def are_waiting_for_resource?
      @waiting_resource > 0
    end

    private def sync
      @mutex.lock
      begin
        yield
      ensure
        @mutex.unlock
      end
    end

    private def unsync
      @mutex.unlock
      begin
        yield
      ensure
        @mutex.lock
      end
    end
  end
end
