$LOAD_PATH << __dir__

require 'logger'
require 'ghettovcb-scheduler/config'
require 'ghettovcb-scheduler/scheduler'
require 'ghettovcb-scheduler/hypervisor'

logger = Logger.new(STDOUT)

config = Config::load(File.expand_path('../config/config.yaml', __dir__))
logger.level = Logger.const_get(config.log_level)

logger.debug(config.inspect)

scheduler = Scheduler.new(config.tasks)

scheduler.run_tasks_server do |server_def|
    Hypervisor.connect(server_def.hostname, config.default_user) do |server|
      puts server.hostname
      puts server.copy_ghetto_script
      # create the config files

      #
    end
end