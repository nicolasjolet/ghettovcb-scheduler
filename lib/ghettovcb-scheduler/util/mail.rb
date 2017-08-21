require 'net/smtp'

module Mail
  class << self
    attr_accessor :smtp_host, :mail_from, :rcpt_to

    def send(message, rcpt: null)
      Net::SMTP.start(smtp_host) do |smtp|
        smtp.send_message("From: #{mail_from}\r\nSubject: Backup\r\n#{message}", mail_from, rcpt || rcpt_to)
      end
    end
  end
end