class ContactMailer < ApplicationMailer
  def new_message(contact_message)
    @contact_message = contact_message
    mail(
      to: ENV.fetch("ADMIN_NOTIFICATION_EMAIL", WEDDING[:from_email].match(/<(.+)>/)[1]),
      reply_to: contact_message.email,
      subject: "Website message from #{contact_message.name}"
    )
  end
end
