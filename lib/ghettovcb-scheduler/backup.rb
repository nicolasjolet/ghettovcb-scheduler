require 'ghettovcb-scheduler/server/hypervisor'
require 'ghettovcb-scheduler/server/backup_server'
require 'ghettovcb-scheduler/scheduler'

module Backup

  module_function
  def save(tasks)
    Scheduler.run_tasks_server(tasks) do |server_def|
      begin
        Hypervisor.connect(server_def) do |server|

          App::logger.debug("Backup start for #{server.real_hostname}")

          case server.get_ghetto_running_state
            when :active
              raise "GhettoVCB is already running on #{server.real_hostname}"
            when :wrong
              App::logger.warn("Ghetto working file is present but script is not running on #{server.real_hostname}")
              App::logger.debug('=> Clean ghetto wrorking directory')
              server.fix_wrong_ghetto_state
          end

          server.exec_ghetto_script

          App::logger.debug('Save to drop done')

          App::logger.debug('Archiving in vault')

          BackupServer.move_to_vault()

          App::logger.debug('Archiving in vault done')
        end
      rescue => e
        App::logger.error(e.message)
      end
    end
  end
end