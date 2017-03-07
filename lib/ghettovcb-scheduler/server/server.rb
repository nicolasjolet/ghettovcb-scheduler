require 'open3'


class CommandFailed < StandardError; end
class CommandExecutionFailed < StandardError; end

class CmdReturn
  attr_accessor :stdout, :stderr, :exit_code

  def initialize(args)
    args.each do |h, v|
      send("#{h}=", v)
    end
  end
end

module LocalServer
  module_function
  def execute_server_cmd(cmd, send_data: nil, exception_on_error: true, remove_trailing_newline: true)

    stdout, stderr, status = Open3.capture3(cmd, stdin_data: send_data)

    raise CommandExecutionFailed, "Couldn't execute command #{cmd}" unless status.success?

    raise CommandFailed, "Command returned exit code #{status.exitstatus} - #{stderr}" if exception_on_error && status.exitstatus != 0

    CmdReturn.new(stdout: remove_trailing_newline ? stdout.chomp : stdout,
                  stderr: stderr,
                  exit_code: status.exitstatus)
  end
end