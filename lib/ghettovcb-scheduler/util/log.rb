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

  def write(level: nil, message:, details: nil)
    _level = convert_severity(level)
    filtered_items = @items.select {|l| _level.nil? || l.level <= _level}
    filtered_items.each do |l|
      case l.listen_to
        when Mail then
          l.listen_to.send(details, subject: severity_to_s(level) + ' -- ' + message)
        when Logger then
          l.listen_to.add(level, message + (details && "\r\n" + details).to_s)
      end
    end
  end

  private
  def add(level, listen_to)
    @items << Listener.new(level: convert_severity(level), listen_to: listen_to)
  end

  def convert_severity(severity)
    return severity if severity.is_a?(Integer)
    Logger::Severity.const_get(severity.to_s.upcase)
  end

  def severity_to_s(severity)
    return severity if severity.is_a?(String)

    Logger::Severity.constants.find { |k| Logger::Severity.const_get(k) == severity}.to_s
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

    def debug(message, details = nil)
      write(DEBUG, message, details: details)
    end

    def info(message, details = nil)
      write(INFO, message, details: details)
    end

    def warn(message, details = nil)
      write(WARN, message, details: details)
    end

    def error(message, details = nil)
      write(ERROR, message, details: details)
    end

    def fatal(message, details = nil)
      write(FATAL, message, details: details)
    end

    private
    def write(severity = nil, message, details: nil)
      @listeners.write(level: severity, message: message, details: details)
    end
  end
end