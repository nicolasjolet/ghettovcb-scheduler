#$LOAD_PATH << __dir__

require 'ghettovcb-scheduler/config'
require 'ghettovcb-scheduler/scheduler'
require 'logger'

logger = Logger.new(STDOUT)

config = Config::load(File.expand_path('../config/config.yaml', __dir__))
logger.level = Logger.const_get(config.log_level)

logger.debug(config.inspect)

scheduler = Scheduler.new(config.tasks, config.default_user)

scheduler.run_tasks