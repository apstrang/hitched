require "test_helper"

class Admin::MenuOptionsControllerTest < ActionDispatch::IntegrationTest
  def admin_auth
    { "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials("admin", "password") }
  end

  test "lists menu options with how many guests chose each" do
    get admin_menu_options_path, headers: admin_auth
    assert_response :success
    assert_select "td", text: "Chicken"
  end

  test "creates a menu option" do
    assert_difference "MenuOption.count", 1 do
      post admin_menu_options_path, headers: admin_auth,
        params: { menu_option: { name: "Mushroom risotto", description: "Vegetarian", sort_order: 5, active: "1" } }
    end
    assert_redirected_to admin_menu_options_path
    assert MenuOption.find_by(name: "Mushroom risotto").active?
  end

  test "rejects a blank name" do
    post admin_menu_options_path, headers: admin_auth, params: { menu_option: { name: "" } }
    assert_response :unprocessable_entity
  end

  test "hides an option from guests" do
    patch admin_menu_option_path(menu_options(:fish)), headers: admin_auth, params: { menu_option: { active: "0" } }
    assert_redirected_to admin_menu_options_path
    assert_not menu_options(:fish).reload.active?
  end

  test "won't delete an option guests have chosen" do
    assert_no_difference "MenuOption.count" do
      delete admin_menu_option_path(menu_options(:chicken)), headers: admin_auth
    end
    assert_match "Hide it instead", flash[:alert]
  end

  test "deletes an unused option" do
    assert_difference "MenuOption.count", -1 do
      delete admin_menu_option_path(menu_options(:fish)), headers: admin_auth
    end
  end
end
