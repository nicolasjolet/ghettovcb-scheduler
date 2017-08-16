require 'ghettovcb-scheduler/server/server'

module BackupServer
  include LocalServer

  class << self
    def free_space
      execute_server_cmd("df /var/share --output='avail' | tail -1").stdout.to_i
    end

    def move_to_vault(vault_path: '/var/backup-vault', backup_name:, backup_vms:)
      nil.to_s
    end
  end

end