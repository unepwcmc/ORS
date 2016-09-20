# == Schema Information
#
# Table name: users
#
#  id                  :integer          not null, primary key
#  email               :string(255)      not null
#  persistence_token   :string(255)      not null
#  crypted_password    :string(255)      not null
#  password_salt       :string(255)      not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  login_count         :integer          default(0), not null
#  failed_login_count  :integer          default(0), not null
#  last_request_at     :datetime
#  current_login_at    :datetime
#  last_login_at       :datetime
#  current_login_ip    :string(255)
#  last_login_ip       :string(255)
#  perishable_token    :string(255)      not null
#  single_access_token :string(255)      not null
#  first_name          :string(255)
#  last_name           :string(255)
#  creator_id          :integer          default(0)
#  language            :string(255)      default("en")
#  category            :string(255)
#  region              :text             default("")
#  country             :text             default("")
#
#
require 'test_helper'

class UserTest < ActiveSupport::TestCase

  setup do
    User.delete_all
  end

  context "User with first name Simao and last name Castro" do
    setup do
      @user = FactoryGirl.create(:user)
    end

    should "return @user.full_name as the user's full_name" do
      assert_equal (@user.first_name + " " + @user.last_name), @user.full_name
    end
  end

  #@user.authorized_submtter_of?(@questionnaire)
  context "1 user 1 questionnaire, with user not authorized" do
    setup do
      User.delete_all
      @user = FactoryGirl.create(:user)
      @questionnaire = FactoryGirl.create(:questionnaire, user: @user, last_editor: @user)
      questionnaire_field = FactoryGirl.create(:questionnaire_field, questionnaire: @questionnaire)
    end

    should "return false when checking if @user is an authorized submitter of @questionnaire" do
      assert_equal false, @user.authorized_submitter_of?(@questionnaire)
    end
  end

  #Add user to a group and check if it was successfully added
  context "1 user to be added to group Test" do
    subject{ @user; @users }
    setup do
      @user = FactoryGirl.create(:user)
      @user2 = FactoryGirl.create(:user, :first_name => "Mariana", :last_name =>"Domingos", :email => "mariana@domingos.pt")
      users = {@user.id => "don't care", @user2.id => "don't care"}
      group = "Test"
      @users = User.add_users_to_group(users, group)
    end

    should "return 1 group in the user's group list" do
      assert_equal 1, @user.group_list.count
    end

    should "return 2 users n the @users list" do
      assert_equal 2, @users.size
    end
  end

end
