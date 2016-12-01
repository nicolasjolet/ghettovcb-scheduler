require 'net/ssh'

class Hypervisor
  class CommandFailed < StandardError
  end

  class CommandExecutionFailed < StandardError
  end

  class << self
    def connect(hostname, user, password=nil)
      raise 'You need to provide a code block' unless block_given?

      Net::SSH.start(hostname, user) { |ssh| yield new(ssh) }
    end

    private :new
  end

  def initialize(ssh_connection)
     @ssh_connection = ssh_connection
  end

  def hostname
    execute_server_cmd('hostname')[:stdout]
  end

  def copy_ghetto_script
    execute_server_cmd('cp -fR /vmfs/volumes/scripts/ghettovcb-scheduler/bin/ghettovcb /tmp')
  end

  def create_ghetto_config

  end

  def exec_ghetto_script

  end

  private
  # @param [String] cmd
  def execute_server_cmd(cmd)
    stdout_data, stderr_data = '', ''
    exit_code, exit_signal = nil, nil

    @ssh_connection.open_channel do |channel|
      channel.exec(cmd) do |_, success|
        raise CommandExecutionFailed, "FAILED: couldn't execute command #{cmd}" unless success

        channel.on_data { |_, data| stdout_data += data }

        channel.on_extended_data { |_, _, data| stderr_data += data }

        channel.on_request('exit-status') { |_, data| exit_code = data.read_long }

        channel.on_request('exit-signal') { |_, data| exit_signal = data.read_long }
      end
    end
    @ssh_connection.loop

    raise CommandFailed, "Command returned exit code #{exit_code}" unless exit_code == 0

    {
        stdout: stdout_data,
        stderr: stderr_data,
        exit_code: exit_code,
        exit_signal: exit_signal
    }
    #@ssh_connection.exec!(cmd)
  end
end