require 'yaml'
require 'ghettovcb-scheduler/util/scheduler'
require 'ghettovcb-scheduler/server/hypervisor'
require 'ghettovcb-scheduler/util/mail'

module Config
  module_function

  def load(path)
    raw_yaml = YAML.load_file(path)

    App.logger.level = Logger.const_get(raw_yaml['log_level'])

    default = raw_yaml['default']
    Mail.rcpt_to = raw_yaml['rcpt_to']
    Mail.mail_from = raw_yaml['mail_from']
    Mail.smtp_host = raw_yaml['smtp_host']

    App.scheduler.tasks = raw_yaml['tasks'].map do |(k, v)|
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