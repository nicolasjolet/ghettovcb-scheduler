require 'yaml'
require 'ghettovcb-scheduler/util/scheduler'
require 'ghettovcb-scheduler/server/hypervisor'
require 'ghettovcb-scheduler/util/mail'
require 'ghettovcb-scheduler/util/log'

module Config
  module_function

  def load(path)
    raw_yaml = YAML.load_file(path)

    default = raw_yaml['default']

    Mail.mail_from = raw_yaml['smtp']['mail_from']
    Mail.smtp_host = raw_yaml['smtp']['host']
    Mail.subject = raw_yaml['smtp']['subject']

    raw_yaml['log']['listeners'].each do |i|
      if i['mail']
        Log.listeners.add_mail(i['threshold'], rcpt_to: i['mail'])
      elsif i['file']
        Log.listeners.add_file(i['threshold'], file_path: i['file'])
      elsif i['console']
        Log.listeners.add_console(i['threshold'])
      else
          raise ParseError, 'unknown listener defined'
      end
    end

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