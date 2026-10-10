module Admin
  class ContactMessagesController < BaseController
    def index
      @contact_messages = ContactMessage.order(created_at: :desc)
    end

    def destroy
      ContactMessage.find(params[:id]).destroy
      redirect_to admin_contact_messages_path, notice: "Message deleted."
    end
  end
end
