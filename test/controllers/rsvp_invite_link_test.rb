require "test_helper"

class RsvpInviteLinkTest < ActionDispatch::IntegrationTest
  test "permanent link lets a guest past the gate and into their RSVP" do
    invite = invites(:smiths)

    get rsvp_invite_path(token: invite.rsvp_token)
    assert_redirected_to rsvp_show_path(token: invite.rsvp_token)

    follow_redirect!
    assert_response :success
    assert_select "h1", /The Smith Family/

    get root_path
    assert_response :success
  end

  test "permanent link still works long after it was issued" do
    invite = invites(:smiths)

    travel 2.years do
      get rsvp_invite_path(token: invite.rsvp_token)
      assert_redirected_to rsvp_show_path(token: invite.rsvp_token)
    end
  end

  test "unknown token sends an unauthenticated visitor to the gate" do
    get rsvp_invite_path(token: "not-a-real-token")
    assert_redirected_to gate_path
  end

  test "RSVP pages still require the gate without the permanent link" do
    get rsvp_show_path(token: invites(:smiths).rsvp_token)
    assert_redirected_to gate_path
  end

  test "legacy signed management links redirect to the permanent RSVP page" do
    invite = invites(:smiths)
    post gate_path, params: { code: ENV.fetch("WEDDING_INVITE_CODE") }
    token = Rails.application.message_verifier(:rsvp_management).generate(invite.id, expires_in: 30.days)

    get rsvp_manage_path(token: token)
    assert_redirected_to rsvp_show_path(token: invite.rsvp_token)
  end

  test "new invites get a token automatically" do
    invite = Invite.create!(name: "The Parkers", email: "parker@example.com")
    assert_equal 24, invite.rsvp_token.length
  end
end
