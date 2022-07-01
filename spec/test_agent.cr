class TestAgent
  @initialized = false

  def initialize(@destination : String)
  end

  def offset_initialization
    # Simulate initialization time.
    sleep 10
    if rand > 0.995
      raise AgentPool::PoolResourceRefused.new
    end
    @initalized = true
  end

  def handle_cmd(cmd)
    offset_initialization unless @initialized
    puts "Sleeping."
    rand(0..@destination.size).times do
      puts "Sleeping."
      if rand > 0.99
        raise AgentPool::PoolResourceLost.new(self)
      end
      sleep(rand)
    end
    puts "Done Sleeping."
  end

  def close
    return true
  end
end
