
class Task
  attr_reader :name, :servers

  def initialize(name:, servers:)
    @name = name
    @servers = servers
  end
end

class Scheduler
  attr_accessor :tasks

  def run
		tasks.map { |task| Thread.new { task.servers.each { |server| yield server } } }
    .each(&:join) # wait all threads
	end

end