class ChangeEmailSubjectDefault < ActiveRecord::Migration
  def change
    change_column_default :questionnaire_fields, :email_subject, :default => "Online Reporting System"
  end
end
