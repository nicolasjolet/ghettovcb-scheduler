# Find the parent directory of this file and add it to the front
# of the list of locations to look in when using require
$:.unshift(__dir__)

require 'logger'
require 'ghettovcb-scheduler/util/config'
require 'ghettovcb-scheduler/backup'

module App
  class << self
    def logger
      @logger
    end

    def setup
      @logger = Logger.new(STDOUT)

      # TODO: use a factory to create tasks from config (and use hypervisor class instead of copy each)
      @config = Config.load(File.expand_path('../config/config.yaml', __dir__))

      @logger.debug('Current configuration:')
      @logger.debug(@config.inspect)
    end

    def run
      # check available size
      logger.debug { "Backup server free space: #{BackupServer.free_space}" } unless Gem.win_platform?

      # perform backups
      Backup.save(@config.tasks)
    end
  end
end


# Only run the following code when this file is the main file being run
# instead of having been required or loaded by another file
if __FILE__ == $PROGRAM_NAME

  App.setup
  App.run

end