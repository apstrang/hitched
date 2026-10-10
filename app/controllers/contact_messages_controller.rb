class ContactMessagesController < ApplicationController
  before_action -> { require_page_enabled!(:contact) }

  def new
    @contact_message = ContactMessage.new
  end

  def create
    @contact_message = ContactMessage.new(contact_message_params)
    if @contact_message.save
      ContactMailer.new_message(@contact_message).deliver_later
      redirect_to contact_path, notice: "Thanks for your message! We'll get back to you soon."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def contact_message_params
    params.require(:contact_message).permit(:name, :email, :body)
  end
end
