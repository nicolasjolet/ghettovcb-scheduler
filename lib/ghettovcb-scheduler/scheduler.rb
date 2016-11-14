require 'net/ssh'

class Scheduler
	def initialize(tasks)
		@tasks = tasks
	end
	
	def run_tasks
		# TODO: sanitarize : ensure we do not backup same target (server+vm) in different tasks
		threads = []
		
		@tasks.each do |task|
			threads << Thread.new {
				task.servers.each do |server|
					Net::SSH.start(server) do |ssh|
					
					end
					system()
				end
			}

		end
	end
	
	def task_status (task)

	end
	
	def length
		@tasks.length
	end	
end