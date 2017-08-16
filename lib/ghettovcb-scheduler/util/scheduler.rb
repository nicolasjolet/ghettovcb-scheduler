
class Task
  attr_reader :name, :servers
  attr_accessor :status

  def initialize(name:, servers:)
    @name = name
    @servers = servers
    @status = :scheduled
  end
end

class Scheduler
  attr_accessor :tasks

  def run
    tasks.map do |task|
      task.status = :running
      Thread.new do
        task.servers.each { |server| yield server }
        task.status = :done
      end
    end
         .each(&:join) # wait all threads
  end
end