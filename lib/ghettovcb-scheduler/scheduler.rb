class Scheduler
	def initialize(tasks)
		@tasks = tasks
	end

  def run_tasks_server
		# TODO: sanatize : ensure we do not backup same target (server+vm) in different tasks
		threads = []

		@tasks.each do |task|
      threads << Thread.new do
        task.servers.each do |server|
				  yield server
        end
			end
    end
    threads.each(&:join)
	end
	
	def length
		@tasks.length
	end	
end