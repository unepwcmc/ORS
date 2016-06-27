class DropQuestionnaireSources < ActiveRecord::Migration
  def self.up
    execute 'DROP TABLE IF EXISTS questionnaire_sources'
  end

  def self.down
  end
end
