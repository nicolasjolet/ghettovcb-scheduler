$LOAD_PATH << __dir__

require 'ghettovcb-scheduler/config'
require 'ghettovcb-scheduler/scheduler'
require 'logger'

logger = Logger.new(STDOUT)

config = Config::load(File.join(__dir__, '../config/config.yaml'))
logger.level = Logger.const_get config.log_level

logger.debug(config.inspect)

scheduler = Scheduler.new(config.tasks, config.default_user)

scheduler.run_tasks