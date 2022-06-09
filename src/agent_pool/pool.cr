module AgentPool
  class Pool
    # TODO: Spread out load and spin up new agents when necessary.
    # Bonus: Turn the algorithm into a shard for use in many different fiber pooling systems.
    # TODO: Lazily clean up old agents that are no longer in use.

    # TODO: Respect these dynamic limits.
    MAX_AGENTS_PER_DESTINATION = 20
    MAX_TOTAL_AGENTS = MAX_AGENTS_PER_DESTINATION * 1000

    @pool_of_agents : Hash(String, Array(Channel(Command)))

    def initialize
      @pool_of_agents = Hash(String, Array(Channel(Command))).new
    end

    def handle_command(cmd : Command, destination : String)
      Channel.send_first(cmd, self.channels_for_destination(destination))
    end

    def channels_for_destination(destination : String) : Array(Channel(Command))
      return @pool_of_agents[destination] ||= [create_agent_for_destination(destination)]
    end

    def create_agent_for_destination(destination : String) : Channel(Command)
      channel = Channel(Command).new
      spawn Agent.spawn_agent(destination, channel)
      return channel
    end
  end
end
