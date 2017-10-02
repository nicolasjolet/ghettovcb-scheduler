require 'logger'
require 'ghettovcb-scheduler/util/mail'


class Listener
  attr_accessor :level, :listen_to

  def initialize(level:, listen_to:)
    @level = level
    @listen_to = listen_to
  end
end

class Listeners
  include Logger::Severity

  def initialize
    @items = []
  end

  def remove_all!(level: nil)
    _level = convert_severity(level)
    @items.delete_if {|l| _level.nil? || l.level == _level}
  end

  def add_mail(level, rcpt_to:)
    add(level, Mail.new(rcpt_to: rcpt_to))
  end

  def add_console(level)
    add(level, Logger.new(STDOUT))
  end

  def add_file(level, file_path:)
    add(level, Logger.new(file_path))
  end

  def write(level: nil, message:)
    _level = convert_severity(level)
    filtered_items = @items.select {|l| _level.nil? || l.level < _level}
    filtered_items.each do |l|
      case l.listen_to
        when Mail then
          l.listen_to.send(message)
        when Logger then
          l.listen_to.add(level, message)
      end
    end
  end

  private
  def add(level, listen_to)
    @items << Listener.new(level: convert_severity(level), listen_to: listen_to)
  end

  def convert_severity(severity)
    return severity if severity.is_a?(Integer)
    return UNKNOWN if severity.nil?

    case severity.to_s.downcase
      when 'debug'.freeze then DEBUG
      when 'info'.freeze then INFO
      when 'warn'.freeze then WARN
      when 'error'.freeze then ERROR
      when 'fatal'.freeze then FATAL
      when 'unknown'.freeze then UNKNOWN
      else
        raise ArgumentError, "invalid severity : #{severity}"
    end
  end
end

module Log
  @listeners = Listeners.new

  class << self
    include Logger::Severity
    attr_reader :listeners

    def mail_subject=(subject)
      Mail.subject = subject
    end

    def debug(message)
      write(DEBUG, message)
    end

    def info(message)
      write(INFO, message)
    end

    def warn(message)
      write(WARN, message)
    end

    def error(message)
      write(ERROR, message)
    end

    def fatal(message)
      write(FATAL, message)
    end

    private
    def write(severity = nil, message)
      @listeners.write(level: severity, message: message)
    end
  end
end