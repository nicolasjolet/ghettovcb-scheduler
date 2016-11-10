#!/usr/bin/env ruby
require 'classes/config'
require 'classes/scheduler'

config = Config::load('../config/config.yaml')

scheduler = Scheduler.new(config.tasks)

# scheduler.run_tasks