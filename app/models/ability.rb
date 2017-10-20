class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new #guest user.

    if user.role? :admin
      can :manage, :all
    else
      can :create, User do
        user.id.nil?
      end
      if user.role?(:respondent_admin)
        can [:respondents, :submit, :submission, :unsubmit, :download_user_pdf, :to_pdf], Questionnaire
        can [:save_answers, :submission, :load_lazy, :questions, :loop_item_names], Section
        can [:update, :add_document, :add_link], Answer
        can [:show, :update], User, id: user.id
      end
      if user.role?(:super_delegate)
        can [:show, :update], User, id: user.id
      end
      if user.role?(:respondent) || user.is_delegate?
        can :submission, Questionnaire do |questionnaire|
          user.authorized_to_answer? questionnaire
        end
        can [:save_answers, :submission, :load_lazy], Section do |section|
          user.authorized_to_answer? section.questionnaire
        end
        can :change_language, AuthorizedSubmitter
        can [:update, :add_document, :add_link], Answer
        if user.role?(:delegate)
          can [:show, :update], User, id: user.id
        end
        if user.role?(:respondent)
          can [:create], User
          can [:show, :update, :update_submission_page, :upload_list_of, :group, :remove_group, :delegate_section], User, id: user.id
          can [:submit, :download_user_pdf, :to_pdf], Questionnaire do |questionnaire|
            user.authorized_to_answer? questionnaire
          end
          can [:questions, :loop_item_names ], Section do |section|
            user.authorized_to_answer? section.questionnaire
          end
          can :manage, DelegationSection do |delegation_section|
            delegation_section.delegation.user == user
          end
          can :manage, Delegation do |delegation|
            delegation.user == user
          end
        end
      end
    end
  end
end
