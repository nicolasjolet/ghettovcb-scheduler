$LOAD_PATH << __dir__

require 'ghettovcb-scheduler/config'
require 'ghettovcb-scheduler/scheduler'

config = Config::load(File.join(__dir__, '../config/config.yaml'))

scheduler = Scheduler.new(config.tasks)

scheduler.run_tasks