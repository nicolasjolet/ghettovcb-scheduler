# Find the parent directory of this file and add it to the front
# of the list of locations to look in when using require
$:.unshift(__dir__)

require 'ghettovcb-scheduler/util/log'
require 'ghettovcb-scheduler/util/config'
require 'ghettovcb-scheduler/util/scheduler'
require 'ghettovcb-scheduler/server/hypervisor'
require 'ghettovcb-scheduler/server/backup_server'

module App

  class << self
    def scheduler
      @scheduler ||= Scheduler.new
    end

    def load_config
      Config.load(File.expand_path('../config/config.yaml', __dir__))
    end

    def check_ghetto_status(server)
      case server.get_ghetto_running_state
        when :active
          raise "GhettoVCB is already running on #{server.real_hostname}"
        when :wrong
          Log.warn("Ghetto working file is present but script is not running on #{server.real_hostname}")
          Log.debug('=> Clean ghetto working directory')
          server.fix_wrong_ghetto_state
      end
    end

    def run
      load_config

      Log.mail_subject = 'ghettoVCB scheduler'
      Log.info('Global Backup Start')

      scheduler.run_n_connect do |server|
        Log.info("Backup start for #{server.real_hostname} -- " + server.include_list.first)

        check_ghetto_status(server)
        server.save_to_drop

        Log.info("Backup finished for #{server.real_hostname} -- " + server.include_list.first)

        #BackupServer.move_to_vault(backup_name: server.real_hostname, )
      end

      Log.info('Global Backup End')

    rescue => e
      Log.fatal(e.message)
    end
  end

end


# Only run the following code when this file is the main file being run
# instead of having been required or loaded by another file
if __FILE__ == $PROGRAM_NAME
  App.run
end