module Scheduler

  module_function
  def run_tasks_server(tasks)

		tasks.map do |task|
      Thread.new do
        task.servers.each do |server|

				  yield server
        end
			end
    end
    .each(&:join) # wait all threads
	end

end