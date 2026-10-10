require "test_helper"

class Admin::InviteMailingsTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  setup do
    @smiths = invites(:smiths)
    @johnsons = invites(:johnsons)
  end

  def admin_auth
    { "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials("admin", "password") }
  end

  test "invite page shows the household QR code and send buttons" do
    get admin_invite_path(@smiths), headers: admin_auth
    assert_response :success
    assert_select "svg[aria-label=?]", "QR code for http://example.com/r/#{@smiths.rsvp_token}"
    assert_select "a[href=?]", qr_code_admin_invite_path(@smiths, format: :png)
    assert_select "form[action=?]", send_save_the_date_admin_invite_path(@smiths)
    assert_select "form[action=?]", send_invitation_admin_invite_path(@smiths)
  end

  test "downloads the QR code as PNG and SVG" do
    get qr_code_admin_invite_path(@smiths, format: :png), headers: admin_auth
    assert_response :success
    assert_equal "image/png", response.media_type
    assert_match "rsvp-qr-the-smith-family.png", response.headers["Content-Disposition"]

    get qr_code_admin_invite_path(@smiths, format: :svg), headers: admin_auth
    assert_response :success
    assert_equal "image/svg+xml", response.media_type
  end

  test "QR code pages need the admin login" do
    get qr_code_admin_invite_path(@smiths, format: :png)
    assert_response :unauthorized
    get qr_codes_admin_invites_path
    assert_response :unauthorized
  end

  test "printable sheet has every household" do
    get qr_codes_admin_invites_path, headers: admin_auth
    assert_response :success
    assert_select ".qr-card", Invite.count
    assert_select ".qr-url", text: "http://example.com/r/#{@johnsons.rsvp_token}"
  end

  test "bulk save-the-dates go only to households that haven't had one" do
    @johnsons.update_column(:save_the_date_sent_at, 1.day.ago)

    assert_enqueued_emails 1 do
      post admin_send_save_the_dates_path, headers: admin_auth
    end
    assert_redirected_to admin_emails_path
    assert_equal "Save-the-dates sent to 1 invite.", flash[:notice]
    assert @smiths.reload.save_the_date_sent_at

    assert_no_enqueued_emails do
      post admin_send_save_the_dates_path, headers: admin_auth
    end
  end

  test "bulk invitations go only to households that haven't had one" do
    assert_enqueued_emails 2 do
      post admin_send_invitations_path, headers: admin_auth
    end
    assert Invite.where(invitation_sent_at: nil).none?

    assert_no_enqueued_emails do
      post admin_send_invitations_path, headers: admin_auth
    end
  end

  test "resends to one household from its invite page" do
    @smiths.update_column(:invitation_sent_at, 2.days.ago)

    assert_enqueued_email_with RsvpMailer, :invitation, args: [ @smiths ] do
      post send_invitation_admin_invite_path(@smiths), headers: admin_auth
    end
    assert_redirected_to admin_invite_path(@smiths)
    assert_in_delta Time.current, @smiths.reload.invitation_sent_at, 5

    assert_enqueued_email_with RsvpMailer, :save_the_date, args: [ @smiths ] do
      post send_save_the_date_admin_invite_path(@smiths), headers: admin_auth
    end
  end

  test "emails page shows save-the-date and invitation counts" do
    @smiths.update_column(:save_the_date_sent_at, 1.day.ago)
    get admin_emails_path, headers: admin_auth
    assert_response :success
    assert_select "form[action=?] button", admin_send_save_the_dates_path, text: "Send Save-the-Dates to 1 Invite"
    assert_select "form[action=?] button", admin_send_invitations_path, text: "Send Invitations to 2 Invites"
  end

  test "sends a test save-the-date" do
    assert_emails 1 do
      post admin_send_test_email_path(email_type: "save_the_date"), headers: admin_auth
    end
    assert_equal "Save the Date — #{WEDDING[:couple_names_possessive]} Wedding", ActionMailer::Base.deliveries.last.subject
  end
end
