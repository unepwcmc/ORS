class AddCanViewAllQuestionnaireBooleanToDelegations < ActiveRecord::Migration
  def change
    add_column :delegations, :can_view_all_questionnaire, :boolean, default: false
  end
end
