class ChangeDelegationColumnCanViewAllQuestionnaire < ActiveRecord::Migration
  def up
    rename_column :delegations, :can_view_all_questionnaire, :can_view_only_assigned_sections
  end

  def down
    rename_column :delegations, :can_view_only_assigned_sections, :can_view_all_questionnaire
  end
end
