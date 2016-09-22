class FixEmailSubjectDefaultValue < ActiveRecord::Migration
  def change
    change_column_default :questionnaire_fields, :email_subject, "Online Reporting System"

    execute <<-SQL
      UPDATE questionnaire_fields
      SET email_subject='Online Reporting System'
      WHERE email_subject='---\n:default: Online Reporting System\n'
    SQL
  end
end
