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
        task.servers.each do |server|
          yield server
        end
        task.status = :done
      end
    end
        .each(&:join) # wait all threads
  end

  def run_n_connect
    run do |server_def|
      server_def.connect do |server|
        server.get_final_vm_list_translated.each do |vm|
          server_c = server.clone
          server_c.include_list = [vm]
          server_c.exclude_list = []
          yield server_c
        end
      end
    end
  end
end