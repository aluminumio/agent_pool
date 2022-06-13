require "./spec_helper"

describe AgentPool do
  it "queues agents" do
    pool = AgentPool::Pool.new
    destinations = ["aaaa", "bbbb", "ccc", "ddd"]
    fibers = [] of Fiber
    1000.times do |i|
      destination = destinations.sample
      destination = Random.new.hex(rand(2..5)) if rand(1..5) == 5
      cmd = AgentPool::Command.new(value: rand(UInt32))
      puts "Try ##{i} : #{destination}"
      fibers << pool.handle_command(cmd, destination)
      #puts "Res: #{res.inspect}"
    end
    while fibers.map(&.dead?).includes?(false)
      sleep(0.2)
      puts "Open Connections: #{pool.stats.open_connections}"
      puts "Idle Connections: #{pool.stats.idle_connections}"
    end
  end

  it "returns stats" do
    pool = AgentPool::Pool.new
    pool.stats.open_connections.should eq 0
  end
end
