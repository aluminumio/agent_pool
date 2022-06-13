# agent_pool

A shard to handle agent pooling with reusable connections.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     agent_pool:
       github: aluminumio/agent_pool
   ```

2. Run `shards install`

## Usage

```crystal
require "agent_pool"

pool = AgentPool::AgentPool(Agent).new
agent = pool.checkout("destination")
spawn do
  agent.do_work("abcd")
  pool.release(agent, "destination")
end
```

TODO: Write usage instructions here

## Development

TODO: Handle timeouts raised by agents.

## Contributing

1. Fork it (<https://github.com/your-github-user/agent_pool/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [usiegl00](https://github.com/usiegl00) - creator and maintainer
