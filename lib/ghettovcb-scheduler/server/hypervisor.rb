require 'ghettovcb-scheduler/server/ssh_server'

class Hypervisor < SSHServer
  attr_accessor :exclude_list, :include_list, :backup_server

  def all_vm?
    case vms_included
      when Array
        vms_included.empty?
      when String
        vms_included.in?( %w(all ALL *) )
      else
        false
    end
  end

  class << self
    def connect(server_def)
      super(server_def.hostname, user: server_def.user) do |x|
        x.exclude_list = server_def.vms_excluded || []
        x.include_list = server_def.vms_included || []
        yield x
      end
    end
  end

  def copy_ghetto_script(local_path=File.expand_path('../../../bin/ghettovcb/ghettoVCB.sh', __dir__), remote_path='/tmp/ghettovcb/ghettoVCB.sh')
    #@ssh_connection.scp.upload!(local_path, remote_path, recursive: true)  # removed because slow process
    file_cp(local_path, target: remote_path)
    # ensure executable flag is set
    chmod(remote_path, mod: 'a+x')
  end

  def create_ghetto_config(config_path='/tmp/ghettovcb/ghettoVCB.conf')
    config = [] << 'ENABLE_NON_PERSISTENT_NFS=1'  # Create NFS volume
    config << 'UNMOUNT_NFS=1'                     # Unmount after backup
    # TODO: use the server defined in the config
    config << 'NFS_SERVER=10.69.0.20'
    config << 'NFS_MOUNT=/var/share/backup-drop'
    config << 'NFS_LOCAL_NAME=backup-drop'
    config << 'NFS_VM_BACKUP_DIR=' + real_hostname
    config << 'VM_BACKUP_ROTATION_COUNT=1'
    config << 'ALLOW_VMS_WITH_SNAPSHOTS_TO_BE_BACKEDUP=1'
    file_write(config_path, content: config)

    # translate all id to vm_name
    file_write('/tmp/ghettovcb/vmlist', content: tr_id_to_name(include_list)) unless all_vm?
    file_write('/tmp/ghettovcb/vmblacklist', content: tr_id_to_name(exclude_list)) unless exclude_list.empty?
  end

  def get_nfs_mounts
    execute_server_cmd("vim-cmd hostsvc/summary/fsvolume | grep ' NFS ' | cut -d ' ' -f1").stdout.split(/\n+/)
  end

  def get_ghetto_running_state
    return :inactive unless file_exists?('/tmp/ghettoVCB.work/pid')

    process_runs?(file_read('/tmp/ghettoVCB.work/pid')) && :active || :wrong
  end

  def fix_wrong_ghetto_state
    file_delete!('/tmp/ghettoVCB.work/pid')
  end

  def exec_ghetto_script(script_path='/tmp/ghettovcb/ghettoVCB.sh')
    copy_ghetto_script
    create_ghetto_config
    unmount_nfs('backup-drop') # even if it not exists, to ensure script runs fine
    params = [] << '-g /tmp/ghettovcb/ghettoVCB.conf'
    if all_vm?
      params << '-a'
    else
      params << '-f /tmp/ghettovcb/vmlist'
    end
    params << '-e /tmp/ghettovcb/vmblacklist' unless exclude_list.empty?
    execute_server_cmd(script_path + ' ' + params.join(' '))
  end


  private
  def get_vm_name_from_id(id)
    result = execute_server_cmd("vim-cmd vmsvc/get.summary '#{id}' | grep -o 'name = [^,]*'").stdout

    raise CommandFailed, "Trying to get the VM name for the id #{id} has returned an empty result" if result.to_s == ''

    # get then name from 'name = "NAME"'
    result.match(/name = "(.*)"/).captures[0] or raise CommandFailed, "Trying to get the VM name for the id #{id} from #{result} has failed"
  end

  def tr_id_to_name(ids)
    raise ArgumentError unless ids.is_a?(Array)

    @association ||= execute_server_cmd('vim-cmd vmsvc/getallvms').stdout
                         .split(/\n+/)                                    # convert newline to array
                         .drop(1)                                         # skip header
                         .inject({}) do |memo, x|
                            _id = x[0,4].to_i                             # id + strip spaces
                            memo[_id] = get_vm_name_from_id(_id)      # securely retrieve the name from the id
                            memo
                         end

    ids.map do |x|
      @association[x] || x
    end
  end

  def unmount_nfs(nfs_name)
    #TODO: use name from config
    execute_server_cmd("vim-cmd hostsvc/datastore/destroy #{nfs_name}", exception_on_error: false)
  end
end