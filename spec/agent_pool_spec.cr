require "./spec_helper"

describe AgentPool do
  it "queues agents" do
    pool = TestPool.new
    destinations = ["aaaa", "bbbb", "ccc", "ddd"]
    chans = [] of Channel(Exception?)
    1000.times do |i|
      destination = destinations.sample
      destination = Random.new.hex(rand(2..5)) if rand(1..5) == 5
      cmd = TestPool::Command.new(value: rand(UInt32))
      puts "Try ##{i} : #{destination}"
      chans << pool.handle_command(cmd, destination)
      # puts "Res: #{res.inspect}"
    end

    done = false
    spawn do
      until done
        sleep(0.2)
        puts "Open Connections: #{pool.stats.open_connections}"
        puts "Idle Connections: #{pool.stats.idle_connections}"
      end
    end

    chans.each do |chan|
      x = chan.receive
      raise x if x
    end

    done = true
  end

  it "returns stats" do
    pool = TestPool.new
    pool.stats.open_connections.should eq 0
  end
end
