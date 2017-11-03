require 'net/smtp'

class Mail
  class << self
    attr_accessor :smtp_host, :mail_from, :subject
  end

  attr_accessor :rcpt_to

  def initialize(rcpt_to:)
    @rcpt_to = rcpt_to
  end

  def send(message, subject: nil)
    Net::SMTP.start(Mail.smtp_host) do |smtp|
      smtp.send_message("From: #{Mail.mail_from}\n"\
                        "Subject: #{Mail.subject}#{subject}\n"\
                        "#{message}",
                         Mail.mail_from, rcpt_to)
    end
  end
end