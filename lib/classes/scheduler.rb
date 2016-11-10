class Scheduler
	def initialize(tasks:)
		@tasks = tasks
	end
	
	def run_tasks
		@tasks.each do |task|
		
			threads = []
			threads << Thread.new { system() }
			
		end
	end
	
	def length
		@tasks.length
	end	
end