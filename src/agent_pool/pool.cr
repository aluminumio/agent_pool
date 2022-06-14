module AgentPool
  class Pool
    # TODO: Spread out load and spin up new agents when necessary.
    # Bonus: Turn the algorithm into a shard for use in many different fiber pooling systems.
    # TODO: Lazily clean up old agents that are no longer in use.

    # TODO: Respect these dynamic limits.
    MAX_AGENTS_PER_DESTINATION = 20
    MAX_TOTAL_AGENTS = 1000

    @pool_of_agents : AgentPool(Agent)

    def initialize
      @pool_of_agents = AgentPool.new(max_pool_size: MAX_TOTAL_AGENTS) {|destination| create_agent_for_destination(destination) }
    end

    def handle_command(cmd : Command, destination : String)
      agent = @pool_of_agents.checkout(destination)
      spawn do
        agent.handle_cmd(cmd)
        @pool_of_agents.release(agent, destination)
      end
    end

    def create_agent_for_destination(destination : String) : Agent
      return Agent.new(destination)
    end

    def stats
      return @pool_of_agents.stats
    end
  end
end
