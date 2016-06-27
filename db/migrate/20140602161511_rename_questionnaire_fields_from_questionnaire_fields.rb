class RenameQuestionnaireFieldsFromQuestionnaireFields < ActiveRecord::Migration
  def self.up
    change_column :questionnaire_fields, :email_subject, :string, :default => "Bern Convention - Online Reporting System"
  end

  def self.down
    change_column :questionnaire_fields, :email_subject, :string, :default => "CMS Family - Online Reporting System"
  end
end
