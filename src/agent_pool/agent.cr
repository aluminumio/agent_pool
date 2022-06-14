module AgentPool
  class Agent
    @initialized = false

    def initialize(@destination : String)
    end

    def offset_initialization
      # Simulate initialization time.
      sleep 10
      @initalized = true
    end

    def handle_cmd(cmd)
      offset_initialization unless @initialized
      puts "Sleeping."
      rand(0..@destination.size).times do
        puts "Sleeping."
        sleep(rand)
      end
      puts "Done Sleeping."
    end

    def close
      return true
    end
  end
end
