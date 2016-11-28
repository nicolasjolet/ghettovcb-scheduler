require 'net/ssh'

class Scheduler
	def initialize(tasks, default_user)
		@tasks = tasks
		@default_user = default_user
	end
	
	def run_tasks
		# TODO: sanatize : ensure we do not backup same target (server+vm) in different tasks
		threads = []

		@tasks.each do |task|
      threads << Thread.new do
				task.servers.each do |server|
					Net::SSH.start(server.ip, @default_user) do |ssh|
						ssh.exec!('mkdir /tmp/ghettovcb && cp -fR /vmfs/volumes/scripts/ghettovcb-scheduler/bin/ghettovcb /tmp')
						# create the config files

						#
					end
				end
			end
    end
    threads.each{|thd| thd.join}
	end
	
	def task_status (task)

	end
	
	def length
		@tasks.length
	end	
end