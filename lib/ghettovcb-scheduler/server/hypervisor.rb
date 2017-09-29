require 'ghettovcb-scheduler/server/ssh_server'
require 'ghettovcb-scheduler/util/core_ext'

module HypervisorInterface
  attr_reader :hostname
  attr_accessor :exclude_list, :include_list, :user, :password, :backup_server

  def all_vm?
    case @include_list
      when Array
        @include_list.empty?
      when String
        @include_list.in?(%w(all ALL *))
      else
        false
    end
  end
end

class HypervisorDef
  include HypervisorInterface

  def initialize(hostname, include: [], exclude: [], user: nil, password: nil, backup_server: nil)
    raise "server's hostname cannot be empty" if hostname.to_s == ''
    @hostname = hostname
    @include_list = include
    @exclude_list = exclude
    @user = user
    @password = password
    @backup_server = backup_server
  end

  def connect
    HypervisorConnected.connect(hostname, user: user) do |h|
      h.exclude_list = exclude_list || []
      h.include_list = include_list || []
      h.backup_server = backup_server
      h.password = password
      yield h
    end
  end
end

class HypervisorConnected < SSHServer
  include HypervisorInterface

  def get_ghetto_running_state
    return :inactive unless file_exists?('/tmp/ghettoVCB.work/pid')

    process_runs?(file_read('/tmp/ghettoVCB.work/pid')) && :active || :wrong
  end

  def fix_wrong_ghetto_state
    file_delete!('/tmp/ghettoVCB.work/pid')
    rmdir!('/tmp/ghettoVCB.work/')
  end

  def save_to_drop(script_path='/tmp/ghettovcb/ghettoVCB.sh')
    copy_ghetto_script
    create_ghetto_config
    unmount_nfs('backup-drop') # even if it doesn't exist, to ensure script runs fine
    params = [] << '-g /tmp/ghettovcb/ghettoVCB.conf'
    params << (all_vm? ? '-a' : '-f /tmp/ghettovcb/vmlist')
    params << '-e /tmp/ghettovcb/vmblacklist' unless exclude_list.empty?
    execute_server_cmd(script_path + ' ' + params.join(' '))
  end

  def get_final_vm_list_translated
    include = all_vm? ? get_all_vm_n_id.values : tr_id_to_name(include_list)
    exclude = tr_id_to_name(exclude_list)
    include - exclude
  end

  #**************************************************************************************************#
  private

  def copy_ghetto_script(local_path=File.expand_path('../../../bin/ghettovcb/ghettoVCB.sh', __dir__), remote_path='/tmp/ghettovcb/ghettoVCB.sh')
    #@ssh_connection.scp.upload!(local_path, remote_path, recursive: true)  # removed because slow process
    file_cp(local_path, target: remote_path)
    # ensure executable flag is set
    chmod(remote_path, mod: 'a+x')
  end

  def create_ghetto_config(config_path='/tmp/ghettovcb/ghettoVCB.conf')
    config = [] << 'ENABLE_NON_PERSISTENT_NFS=1' # Create NFS volume
    config << 'UNMOUNT_NFS=1' # Unmount after backup
    config << "NFS_SERVER=#{backup_server}"
    config << 'NFS_MOUNT=/var/share/backup-drop'
    config << 'NFS_LOCAL_NAME=backup-drop'
    config << 'NFS_VM_BACKUP_DIR=' + real_hostname
    config << 'VM_BACKUP_ROTATION_COUNT=1' # number of backup to retain
    config << 'ALLOW_VMS_WITH_SNAPSHOTS_TO_BE_BACKEDUP=1'
    file_write(config_path, content: config)

    # translate all id to vm_name
    unless all_vm?
      file_write('/tmp/ghettovcb/vmlist', content: tr_id_to_name(include_list))
    end
    unless exclude_list.empty?
      file_write('/tmp/ghettovcb/vmblacklist', content: tr_id_to_name(exclude_list))
    end
  end

  def get_nfs_mounts
    execute_server_cmd("vim-cmd hostsvc/summary/fsvolume | grep ' NFS ' | cut -d ' ' -f1").stdout.split(/\n+/)
  end

  def get_vm_name_from_id(id)
    # securely retrieve the name from the id
    result = execute_server_cmd("vim-cmd vmsvc/get.summary '#{id}' | grep -o 'name = [^,]*'").stdout

    raise CommandFailed, "Trying to get the VM name for the id #{id} has returned an empty result" if result.to_s == ''

    # get then name from 'name = "NAME"'
    result.match(/name = "(.*)"/).captures[0] or raise CommandFailed, "Trying to get the VM name for the id #{id} from #{result} has failed"
  end

  def get_all_vm_n_id
    @association ||= execute_server_cmd('vim-cmd vmsvc/getallvms')
        .stdout
        .split(/\n+/) # convert newline to array
        .drop(1) # skip header
        .inject({}) do |memo, x|
          id = x[0, 4].to_i # id + strip spaces
          memo[id] = x.scan(/^\d+\s+([^\[]+)/)[0][0].strip
          # memo[id] = get_vm_name_from_id(_id) # safer but very slow
          memo
        end
  end

  def tr_id_to_name(ids)
    return nil if ids.nil?
    raise ArgumentError unless ids.is_a?(Array)

    ids.map do |x|
      get_all_vm_n_id[x] || x
    end
  end

  def unmount_nfs(nfs_name)
    #TODO: use name from config
    execute_server_cmd("vim-cmd hostsvc/datastore/destroy #{nfs_name}", exception_on_error: false)
  end
end