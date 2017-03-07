require 'yaml'
require 'ghettovcb-scheduler/util/scheduler'
require 'ghettovcb-scheduler/server/hypervisor'

module Config
  module_function

  def load(path)
    raw_yaml = YAML.load_file(path)

    App::logger.level = Logger.const_get(raw_yaml['log_level'])

    default = raw_yaml['default']

    App::scheduler.tasks = raw_yaml['tasks'].map do |(k, v)|
      Task.new(name: k,
               servers: v.map do |vv|
                 HypervisorDef.new(vv['ip'],
                                   include: vv['include'],
                                   exclude: vv['exclude'],
                                   user: vv['user'] || default['user'],
                                   password: vv['password'] || default['password'],
                                   backup_server: vv['backup_server'] || default['backup_server']
                 )
               end
      )
    end
  end
end