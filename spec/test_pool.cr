class TestPool
  class Command
    getter value : UInt32

    def initialize(@value : UInt32)
    end
  end

  # TODO: Spread out load and spin up new agents when necessary.
  # Bonus: Turn the algorithm into a shard for use in many different fiber pooling systems.
  # TODO: Lazily clean up old agents that are no longer in use.

  # TODO: Respect these dynamic limits.
  MAX_AGENTS_PER_DESTINATION =   20
  MAX_TOTAL_AGENTS           = 1000

  @pool_of_agents : AgentPool::AgentPool(TestAgent)

  def initialize
    @pool_of_agents = AgentPool::AgentPool.new(max_pool_size: MAX_TOTAL_AGENTS, retry_attempts: 1000) { |destination| create_agent_for_destination(destination) }
  end

  def handle_command(cmd : Command, destination : String)
    ch = Channel(Exception?).new
    spawn do
      @pool_of_agents.retry(destination) do
        agent = @pool_of_agents.checkout(destination)
        agent.handle_cmd(cmd)
        @pool_of_agents.release(agent, destination)
      end
      ch.send nil
    rescue ex
      ch.send ex
    end
    ch
  end

  def create_agent_for_destination(destination : String) : TestAgent
    return TestAgent.new(destination)
  end

  def stats
    return @pool_of_agents.stats
  end
end
