require "./spec_helper"

describe AgentPool do
  it "queues agents" do
    pool = AgentPool::Pool.new
    destinations = ["aaaa", "bbbb", "ccc", "ddd"]
    1000.times do |i|
      destination = Random.new.hex(rand(2..5))
      case rand(1..5)
      when 1
        destination = destinations[0]
      when 2
        destination = destinations[1]
      when 3
        destination = destinations[2]
      when 4
        destination = destinations[3]
      end
      cmd = AgentPool::Command.new(value: rand(UInt32))
      puts "Try ###{i} : #{destination}"
      res = pool.handle_command(cmd, destination)
      puts "Res: #{res.inspect}"
    end
    sleep
  end
end
