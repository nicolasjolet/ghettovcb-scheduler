require 'yaml'

class TaskServer
	attr_accessor :ip, :vms_included, :vms_excluded
	
	def initialize(ip, include, exclude)
		raise 'server ip cannot be empty' if ip.to_s.empty?
		self.ip = ip
		self.vms_included = include || []
		self.vms_excluded = exclude || []
	end
	
	def all_vm?
		# returns true if array is empty or definded to 'all'
		self.vms_included.to_a.empty? || ['all', 'ALL', '*'].include?(self.vms_included)
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
	attr_accessor :default_user
	attr_accessor :log_level
	
	def initialize
		self.tasks = []
	end
	
	def self.load(path)
		ret = Config.new
		raw_yaml = YAML::load_file(path)
		
		ret.log_level = raw_yaml['log_level']
		ret.default_user = raw_yaml['default_user']
		# load tasks
		raw_yaml['tasks'].each {|k, v| 
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