require 'yaml'
require 'ghettovcb-scheduler/core_ext'

class TaskServer
	attr_accessor :hostname, :vms_included, :vms_excluded
	
	def initialize(hostname, include = [], exclude = [])
    raise "server's hostname cannot be empty" if hostname.to_s == ''
		@hostname = hostname
		@vms_included = include
		@vms_excluded = exclude
	end
	
	def all_vm?
    case vms_included
      when Array
        vms_included.empty?
      when String
        vms_included.in?( %w(all ALL *) )
      else
        false
    end
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
  class << self
    def load(path)
      ret = new
      raw_yaml = YAML::load_file(path)

      ret.log_level = raw_yaml['log_level']
      ret.default_user = raw_yaml['default_user']
      # load tasks
      raw_yaml['tasks'].each do |k, v|
        task = Task.new(k)
        # associate servers
        v.each { |vv| task.servers << TaskServer.new(vv['ip'], vv['include'], vv['exclude']) }
        ret.tasks << task
      end

      return ret
    end

    private :new
  end

	attr_accessor :tasks, :default_user, :log_level
	
	def initialize
		self.tasks = []
	end
	
	def inspect
		YAML::dump(self)
	end
end