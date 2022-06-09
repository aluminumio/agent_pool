module AgentPool
  class Agent
    def self.spawn_agent(destination : String, channel : Channel(Command))
      agent = Agent.build(destination, channel)
      agent.main_loop
    end

    def initialize(@destination : String, @channel : Channel(Command))
    end

    def self.build(destination : String, channel : Channel(Command)) : Agent?
      if destination[0] == 'a'
        # TODO: Handle a failing agent build.
        # return nil
      end
      return Agent.new(destination, channel)
    end

    def main_loop
      # Simulate initialization time.
      sleep(rand * 10)
      puts "Initialized."
      while cmd = @channel.receive?
        # Simulate a highly variable amount of work.
        puts "Sleeping."
        rand(0..@destination.size).times do
          puts "Sleeping."
          sleep(rand)
        end
        puts "Done Sleeping."
      end
    end
  end
end
