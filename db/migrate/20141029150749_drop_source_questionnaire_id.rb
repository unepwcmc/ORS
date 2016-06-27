class DropSourceQuestionnaireId < ActiveRecord::Migration
  def self.up
    sql = <<-SQL
    WITH questionnaires_with_existing_originals AS (
      SELECT questionnaires.*
      FROM questionnaires
      JOIN questionnaires originals
      ON questionnaires.source_questionnaire_id = originals.id
      WHERE questionnaires.original_id IS NULL
    )
    UPDATE questionnaires
    SET original_id = questionnaires.source_questionnaire_id
    FROM questionnaires_with_existing_originals
    WHERE questionnaires_with_existing_originals.id = questionnaires.id
    SQL
    execute sql
    remove_column :questionnaires, :source_questionnaire_id
  end

  def self.down
    add_column :questionnaires, :source_questionnaire_id, :integer
    execute 'UPDATE questionnaires SET source_questionnaire_id = original_id'
  end
end
