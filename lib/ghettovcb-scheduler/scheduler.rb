require 'net/ssh'

class Scheduler
	def initialize(tasks, default_user)
		@tasks = tasks
		@default_user = default_user
	end
	
	def run_tasks
		# TODO: sanitarize : ensure we do not backup same target (server+vm) in different tasks
		threads = []
		
		@tasks.each do |task|
			threads << Thread.new {
				task.servers.each do |server|
					Net::SSH.start(server, @default_user) do |ssh|
						# ensure the lastest version of the backup script is on the server
						puts ssh.exec!(hostname)
						# prepare the config files
						# 
					end
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