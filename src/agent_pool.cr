require "./agent_pool/*"

module AgentPool
  VERSION = "0.1.0"

  class Error < Exception
  end

  class PoolResourceLost(T) < Error
    getter resource : T

    def initialize(@resource : T)
      @resource.close
    end
  end

  class PoolResourceRefused < Error
  end

  class PoolRetryAttemptsExceeded < Error
  end
end
