require "test_helper"

class ContactMessagesControllerTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  test "contact page sits behind the gate" do
    get contact_path
    assert_redirected_to gate_path
  end

  test "renders the contact form" do
    authenticate_gate!
    get contact_path
    assert_response :success
    assert_select "textarea[name='contact_message[body]']"
  end

  test "saves the message and emails the couple" do
    authenticate_gate!
    assert_difference "ContactMessage.count", 1 do
      assert_enqueued_email_with ContactMailer, :new_message, args: ->(args) { args.first.is_a?(ContactMessage) } do
        post contact_path, params: { contact_message: { name: "Aunt Sue", email: "sue@example.com", body: "Is there parking?" } }
      end
    end
    assert_redirected_to contact_path
  end

  test "rejects an incomplete message" do
    authenticate_gate!
    assert_no_difference "ContactMessage.count" do
      post contact_path, params: { contact_message: { name: "Aunt Sue", email: "not-an-email", body: "" } }
    end
    assert_response :unprocessable_entity
  end

  test "admin can read messages" do
    ContactMessage.create!(name: "Aunt Sue", email: "sue@example.com", body: "Is there parking?")
    get admin_contact_messages_path,
      headers: { "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials("admin", "password") }
    assert_response :success
    assert_match "Is there parking?", response.body
  end
end
