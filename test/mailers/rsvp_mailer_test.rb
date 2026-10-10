require "test_helper"

class RsvpMailerTest < ActionMailer::TestCase
  setup do
    @smiths = invites(:smiths)
    @johnsons = invites(:johnsons)
  end

  test "invitation email" do
    email = RsvpMailer.invitation(@smiths)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ "smith@example.com" ], email.to
    assert_equal "You're Invited — #{WEDDING[:couple_names_possessive]} Wedding", email.subject
    assert_match "Dear The Smith Family", email.body.encoded
    assert_match "RSVP Now", email.body.encoded
    assert_match "/r/#{@smiths.rsvp_token}", email.body.encoded
  end

  test "confirmation email" do
    email = RsvpMailer.confirmation(@johnsons)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ "johnson@example.com" ], email.to
    assert_equal "RSVP Confirmation — #{WEDDING[:couple_names_possessive]} Wedding", email.subject
    assert_match "Thank you for your RSVP", email.body.encoded
    assert_match "Mike Johnson", email.body.encoded
    assert_match "Manage Your RSVP", email.body.encoded
  end

  test "update notification email" do
    email = RsvpMailer.update_notification(@johnsons)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ "johnson@example.com" ], email.to
    assert_equal "RSVP Updated — #{WEDDING[:couple_names_possessive]} Wedding", email.subject
    assert_match "updated RSVP", email.body.encoded
    assert_match "Mike Johnson", email.body.encoded
  end

  test "reminder email" do
    email = RsvpMailer.reminder(@smiths)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ "smith@example.com" ], email.to
    assert_equal "We'd love to hear from you — #{WEDDING[:couple_names_possessive]} Wedding", email.subject
    assert_match "haven't received your RSVP", email.body.encoded
    assert_match "RSVP Now", email.body.encoded
  end

  test "emails link to the permanent household RSVP link" do
    email = RsvpMailer.invitation(@smiths)
    text_body = email.text_part.body.decoded

    assert_includes text_body, "http://example.com/r/#{@smiths.rsvp_token}"
  end

  test "invitation includes event details" do
    email = RsvpMailer.invitation(@smiths)
    body = email.body.encoded

    @smiths.events.each do |event|
      assert_match event.name, body
    end
  end

  test "confirmation shows RSVP status for each guest and event" do
    email = RsvpMailer.confirmation(@johnsons)
    body = email.body.encoded

    assert_match "Ceremony", body
    assert_match "Reception", body
  end

  test "emails have both html and text parts" do
    email = RsvpMailer.invitation(@smiths)

    assert_equal 2, email.parts.size
    content_types = email.parts.map(&:content_type)
    assert content_types.any? { |ct| ct.include?("text/html") }
    assert content_types.any? { |ct| ct.include?("text/plain") }
  end

  test "default from address is set" do
    email = RsvpMailer.invitation(@smiths)
    assert_equal [ "rsvp@example.wedding" ], email.from
  end
end
