require "test_helper"

class PasswordResetsControllerTest < ActionController::TestCase
  before(:each) do
    @user = FactoryGirl.create(:user)
  end
  test "on GET to :new" do
    get :new

    assert_response :success
    assert_template :new
  end

  test "on POST to :create" do
    post :create, :email => @user.email

    assert assigns(:user)
    assert_response :redirect
    assert_redirected_to root_path

    #mail = ActionMailer::Base.deliveries.last

    #assert_equal @user.email, mail['from'].to_s
  end

  test "on GET to :edit" do
    get :edit, :id => @user.perishable_token

    assert assigns(:user)
    assert_response :success
    assert_template :edit
  end

  test "on PUT to :update" do
    put :update, :id => @user.perishable_token, :user => { :password => "newpassword" }

    assert assigns(:user)
    assert_response :redirect
    assert_redirected_to @user
  end
end
