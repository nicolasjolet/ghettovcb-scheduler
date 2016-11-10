require 'yaml'

class TaskServer
	attr_accessor :ip, :include, :exclude
	
	def initialize(ip, include, exclude)
		self.ip = ip
		self.include = include
		self.exclude = exclude
	end
end

class Task
	attr_accessor :name, :servers	
	
	def initialize(name)
		self.name = name
		self.servers = []
	end
end

class Config
	attr_accessor :tasks
	
	def initialize
		self.tasks = []
	end
	
	def self.load(path)
		ret = Config.new
		YAML::load_file(path)&.each {|k, v| 
			task = Task.new(k)
			# associate servers
			v&.each {|vv|
				task.servers << TaskServer.new(vv['ip'], vv['include'], vv['exclude'])
			}
			ret.tasks << task
		}
		
		return ret
	end
	
	def inspect
		YAML::dump(self)
	end
end