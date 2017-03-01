require 'yaml'
require 'ghettovcb-scheduler/util/core_ext'

class TaskServer
	attr_reader :hostname, :vms_included, :vms_excluded, :user, :password, :backup_server
	
	def initialize(hostname, include: [], exclude: [], user: nil, password: nil, backup_server: nil)
    raise "server's hostname cannot be empty" if hostname.to_s == ''
		@hostname =       hostname
		@vms_included =   include
		@vms_excluded =   exclude
    @user =           user
    @password =       password
    @backup_server =  backup_server
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
	attr_reader :name, :servers
	
	def initialize(name, servers: [])
		@name = name
		@servers = servers
	end
end


class Config
  attr_reader :tasks

  class << self
    def load(path)
      raw_yaml = YAML.load_file(path)

      App::logger.level = Logger.const_get(raw_yaml['log_level'])
      default = raw_yaml['default']
      def_user = default['user']
      def_backup_server = default['backup_server']

      new(tasks: raw_yaml['tasks'].map do |(k, v)|
        Task.new(k, servers: v.map do |vv|
          TaskServer.new(     vv['ip'],
                         include:       vv['include'],
                         exclude:       vv['exclude'],
                         user:          vv['user'] || def_user,
                         password:      vv['password'],
                         backup_server: vv['backup_server'] || def_backup_server)
          end)
      end)
    end

    private :new
  end
	
	def initialize(tasks: [])
		@tasks = tasks
	end
	
	def inspect
		YAML::dump(self)
	end
end