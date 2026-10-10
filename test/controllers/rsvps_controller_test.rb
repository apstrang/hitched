require "test_helper"

class RsvpsControllerTest < ActionDispatch::IntegrationTest
  setup do
    authenticate_gate!
  end

  test "GET /rsvp renders lookup form" do
    get rsvp_path
    assert_response :success
    assert_select "input[name=query]"
  end

  test "POST /rsvp/lookup with valid email redirects to RSVP form" do
    invite = invites(:smiths)
    post rsvp_lookup_path, params: { query: "smith@example.com" }
    assert_redirected_to rsvp_show_path(token: invite.rsvp_token)
  end

  test "POST /rsvp/lookup with invalid query re-renders form" do
    post rsvp_lookup_path, params: { query: "wrong@example.com" }
    assert_response :unprocessable_entity
  end

  test "POST /rsvp/lookup with blank query re-renders form" do
    post rsvp_lookup_path, params: { query: "" }
    assert_response :unprocessable_entity
  end

  test "GET /rsvp/:token shows RSVP form" do
    invite = invites(:smiths)
    get rsvp_show_path(token: invite.rsvp_token)
    assert_response :success
    assert_select "h1", /The Smith Family/
  end

  test "GET /rsvp/:token with unknown token redirects" do
    get rsvp_show_path(token: "nope")
    assert_redirected_to rsvp_path
  end

  test "GET /rsvp/:id with a numeric invite id no longer exposes the invite" do
    get "/rsvp/#{invites(:smiths).id}"
    assert_redirected_to rsvp_path
  end

  test "POST /rsvp/:token updates RSVPs" do
    invite = invites(:smiths)
    john = guests(:john_smith)
    ceremony = events(:ceremony)

    post rsvp_update_path(token: invite.rsvp_token), params: {
      guests: {
        john.id.to_s => {
          first_name: "John",
          last_name: "Smith",
          menu_option_id: menu_options(:chicken).id,
          dietary_notes: "No nuts",
          rsvps: {
            ceremony.id.to_s => { attending: "true" }
          }
        }
      }
    }

    assert_redirected_to rsvp_show_path(token: invite.rsvp_token)

    john.reload
    assert_equal menu_options(:chicken), john.menu_option
    assert_equal "No nuts", john.dietary_notes

    invite.reload
    assert invite.responded?
  end

  test "POST /rsvp/:token edits guest names" do
    invite = invites(:smiths)
    john = guests(:john_smith)
    ceremony = events(:ceremony)

    post rsvp_update_path(token: invite.rsvp_token), params: {
      guests: {
        john.id.to_s => {
          first_name: "Jonathan",
          last_name: "Smithson",
          menu_option_id: "",
          rsvps: {
            ceremony.id.to_s => { attending: "true" }
          }
        }
      }
    }

    assert_redirected_to rsvp_show_path(token: invite.rsvp_token)

    john.reload
    assert_equal "Jonathan", john.first_name
    assert_equal "Smithson", john.last_name
  end

  test "POST /rsvp/:token adds a new guest" do
    invite = invites(:smiths)
    john = guests(:john_smith)
    ceremony = events(:ceremony)

    assert_difference "Guest.count", 1 do
      post rsvp_update_path(token: invite.rsvp_token), params: {
        guests: {
          john.id.to_s => {
            first_name: "John",
            last_name: "Smith",
            menu_option_id: "",
            rsvps: {
              ceremony.id.to_s => { attending: "true" }
            }
          }
        },
        new_guests: {
          "0" => {
            first_name: "Bobby",
            last_name: "Smith",
            menu_option_id: menu_options(:fish).id,
            dietary_notes: "Gluten free"
          }
        }
      }
    end

    assert_redirected_to rsvp_show_path(token: invite.rsvp_token)

    new_guest = invite.guests.find_by(first_name: "Bobby")
    assert_not_nil new_guest
    assert_equal "Smith", new_guest.last_name
    assert_equal menu_options(:fish), new_guest.menu_option
    assert_equal "Gluten free", new_guest.dietary_notes
  end

  test "POST /rsvp/:token skips new guest with blank first name" do
    invite = invites(:smiths)
    john = guests(:john_smith)
    ceremony = events(:ceremony)

    assert_no_difference "Guest.count" do
      post rsvp_update_path(token: invite.rsvp_token), params: {
        guests: {
          john.id.to_s => {
            first_name: "John",
            last_name: "Smith",
            menu_option_id: "",
            rsvps: {
              ceremony.id.to_s => { attending: "true" }
            }
          }
        },
        new_guests: {
          "0" => {
            first_name: "",
            last_name: "",
            menu_option_id: ""
          }
        }
      }
    end
  end

  test "POST /rsvp/:token removes an existing guest" do
    invite = invites(:smiths)
    john = guests(:john_smith)
    jane = guests(:jane_smith)
    ceremony = events(:ceremony)

    assert_difference "Guest.count", -1 do
      post rsvp_update_path(token: invite.rsvp_token), params: {
        guests: {
          john.id.to_s => {
            first_name: "John",
            last_name: "Smith",
            menu_option_id: "",
            rsvps: {
              ceremony.id.to_s => { attending: "true" }
            }
          },
          jane.id.to_s => {
            _destroy: "1"
          }
        }
      }
    end

    assert_redirected_to rsvp_show_path(token: invite.rsvp_token)
    assert_nil Guest.find_by(id: jane.id)
  end

  test "POST /rsvp/:token does not remove when _destroy is 0" do
    invite = invites(:smiths)
    john = guests(:john_smith)
    ceremony = events(:ceremony)

    assert_no_difference "Guest.count" do
      post rsvp_update_path(token: invite.rsvp_token), params: {
        guests: {
          john.id.to_s => {
            _destroy: "0",
            first_name: "John",
            last_name: "Smith",
            menu_option_id: "",
            rsvps: {
              ceremony.id.to_s => { attending: "true" }
            }
          }
        }
      }
    end
  end

  test "RSVP form offers only menu options shown to guests" do
    get rsvp_show_path(token: invites(:smiths).rsvp_token)
    assert_response :success
    assert_select "select[name='guests[#{guests(:john_smith).id}][menu_option_id]'] option", text: "Chicken"
    assert_select "option", text: /Beef/, count: 0
  end

  test "a hidden option a guest already chose stays selected on their form" do
    john = guests(:john_smith)
    john.update!(menu_option: menu_options(:retired_beef))

    get rsvp_show_path(token: invites(:smiths).rsvp_token)
    assert_select "select[name='guests[#{john.id}][menu_option_id]'] option[selected]", text: /Beef/
  end
end
