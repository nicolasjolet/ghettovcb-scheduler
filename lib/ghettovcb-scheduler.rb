# Find the parent directory of this file and add it to the front
# of the list of locations to look in when using require
$:.unshift(__dir__)

require 'logger'
require 'ghettovcb-scheduler/util/config'
require 'ghettovcb-scheduler/util/scheduler'
require 'ghettovcb-scheduler/server/hypervisor'
require 'ghettovcb-scheduler/server/backup_server'
require 'ghettovcb-scheduler/util/mail'

module App

  class << self
    def scheduler
      @scheduler ||= Scheduler.new
    end

    def logger
      @logger ||= Logger.new(STDOUT)
    end

    def run
      # Load all objects from config
      Config.load(File.expand_path('../config/config.yaml', __dir__))

      # check available size on backup server
      logger.debug { "Backup server free space: #{BackupServer.free_space}" } unless Gem.win_platform?

      # perform backups
      scheduler.run do |server_def|
        server_def.connect do |server|
          logger.info("Backup start for #{server.real_hostname}")

          case server.get_ghetto_running_state
          when :active
            raise "GhettoVCB is already running on #{server.real_hostname}"
          when :wrong
            logger.warn("Ghetto working file is present but script is not running on #{server.real_hostname}")
            logger.debug('=> Clean ghetto working directory')
            server.fix_wrong_ghetto_state
          end

          logger.info('Saving to drop')

          server.save_to_drop

          logger.info('Saved to drop')

          #logger.info('Archiving in vault')

          #BackupServer.move_to_vault(backup_name: server.real_hostname, )

          #logger.info('Archived in vault')
        end
      end

    rescue => e
      logger.fatal(e.message)
      Mail.send("Error during backup : #{e.message}")
    end

  end

end


# Only run the following code when this file is the main file being run
# instead of having been required or loaded by another file
if __FILE__ == $PROGRAM_NAME
  App.run
end