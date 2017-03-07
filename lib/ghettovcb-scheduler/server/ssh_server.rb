require 'net/ssh'
require 'net/scp'

class SSHServer
  attr_reader :hostname, :user

  class << self
    def connect(host, user:)
      raise ArgumentError, 'You need to provide a code block' unless block_given?

      Net::SSH.start(host, user) { |ssh| yield new(ssh, host, user) }
    end

    private :new
  end

  def initialize(ssh_connection, hostname, user)
    @ssh_connection = ssh_connection
    @hostname = hostname
    @user = user
  end

  def real_hostname
    @real_hostname ||= execute_server_cmd('hostname').stdout
  end

  def mkdir(path)
    execute_server_cmd("mkdir -p '#{path}'")
  end

  def chmod(path, mod:)
    execute_server_cmd("chmod #{mod} '#{path}'")
  end

  def file_cp(path, target:)
    mkdir(File.dirname(target))
    file_write(target, content: File.read(path))
  end

  def file_write(path, content:)
    content = content.join("\n") if content.is_a?(Array)
    execute_server_cmd("cat - > '#{path}'", send_data: content)
  end

  def file_exists?(path)
    execute_server_cmd("test -f '#{path}'", exception_on_error: false).exit_code == 0
  end

  def file_delete!(path)
    execute_server_cmd("rm '#{path}'")
  end

  def file_read(path)
    execute_server_cmd("cat '#{path}'").stdout
  end

  def process_runs?(pid)
    execute_server_cmd("ps | grep '^#{pid}'", exception_on_error: false).exit_code == 0
  end

  private
  # @param [String] cmd
  def execute_server_cmd(cmd, send_data: nil, exception_on_error: true, remove_trailing_newline: true)
    stdout_data = stderr_data = ''
    exit_code = exit_signal = nil

    @ssh_connection.open_channel do |channel|
      unless send_data.nil?
        channel.send_data(send_data)
        channel.eof!
      end
      channel.exec(cmd) do |_, success|
        raise CommandExecutionFailed, "Couldn't execute command #{cmd}" unless success

        channel.on_data { |_, data| stdout_data += data }

        channel.on_extended_data { |_, _, data| stderr_data += data }

        channel.on_request('exit-status') { |_, data| exit_code = data.read_long }

        # channel.on_request('exit-signal') { |_, data| exit_signal = data.read_long }
      end
    end
    @ssh_connection.loop

    raise CommandFailed, "Command returned exit code #{exit_code} - #{stderr_data}" if exception_on_error && exit_code != 0

    CmdReturn.new(stdout: (remove_trailing_newline ? stdout_data.chomp : stdout_data),
                  stderr: stderr_data,
                  exit_code: exit_code)
  end

end