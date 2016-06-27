require "test_helper"

class ApplicationProfileControllerTest < ActionController::TestCase
  def setup
    @admin = FactoryGirl.create(:admin)
  end

  test "get index" do
    controller.stubs(current_user: @admin)
    get :index
    assert_response :success
  end

  test "submitting the form creates the profile" do
    controller.stubs(current_user: @admin)
    assert_difference 'ApplicationProfile.count' do
      put :update, application_profile: { title: "MyTitle" }
    end

    @profile = ApplicationProfile.first

    assert_equal "MyTitle", @profile.title
  end

end
