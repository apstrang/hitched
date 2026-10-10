require "test_helper"

class ContactMailerTest < ActionMailer::TestCase
  test "new_message goes to the couple with reply-to set to the guest" do
    message = ContactMessage.create!(name: "Aunt Sue", email: "sue@example.com", body: "Is there parking?")
    email = ContactMailer.new_message(message)

    assert_equal [ "sue@example.com" ], email.reply_to
    assert_equal "Website message from Aunt Sue", email.subject
    assert_match "Is there parking?", email.text_part.body.decoded
  end
end
