class HomeController < ApplicationController

  def index
    if current_user
      if current_user.role?(:respondent)
        @questionnaires = Questionnaire.authorized_questionnaires(current_user)
      elsif current_user.is_delegate?
        redirect_to dashboard_user_delegate_path(current_user.id)
      end
    else
      @user_session = UserSession.new
    end
  end
end
