$LOAD_PATH << __dir__

require 'classes/config'
require 'classes/scheduler'

config = Config::load(File.join(__dir__, '../config/config.yaml'))

scheduler = Scheduler.new(config.tasks)

# scheduler.run_tasks