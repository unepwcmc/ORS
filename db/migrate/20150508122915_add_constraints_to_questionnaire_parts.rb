class AddConstraintsToQuestionnaireParts < ActiveRecord::Migration
  def up
    # add foreign key constraint
    # index on parent_id already in place
    execute <<-SQL
      DELETE FROM questionnaire_parts
      WHERE id IN (
        SELECT qp.id
        FROM questionnaire_parts AS qp
        LEFT OUTER JOIN questionnaire_parts AS qp2 ON qp.parent_id = qp2.id
        WHERE qp2.id IS NULL AND qp.parent_id IS NOT NULL
      )
    SQL

    add_foreign_key :questionnaire_parts,
      :questionnaire_parts, {
        column: :parent_id,
        dependent: :delete
      }

    # add foreign key constraint
    add_index :questionnaire_parts, :questionnaire_id
    execute <<-SQL
      DELETE FROM questionnaire_parts
      WHERE id IN (
        SELECt qp.id
        FROM questionnaire_parts AS qp
        LEFT OUTER JOIN questionnaires AS q ON qp.questionnaire_id = q.id
        WHERE q.id IS NULL AND qp.questionnaire_id IS NOT NULL
      )
    SQL

    add_foreign_key :questionnaire_parts,
      :questionnaires, {
        column: :questionnaire_id,
        dependent: :delete
      }

    # make timestamps NOT NULL
    execute "UPDATE questionnaire_parts SET created_at = NOW() WHERE created_at IS NULL"
    change_column :questionnaire_parts, :created_at, :datetime, null: false
    execute "UPDATE questionnaire_parts SET updated_at = NOW() WHERE updated_at IS NULL"
    change_column :questionnaire_parts, :updated_at, :datetime, null: false
  end

  def down
    remove_foreign_key :questionnaire_parts, column: :parent_id
    remove_index :questionnaire_parts, :questionnaire_id
    remove_foreign_key :questionnaire_parts, column: :questionnaire_id

    change_column :questionnaire_parts,
      :created_at, :datetime, null: true
    change_column :questionnaire_parts,
      :updated_at, :datetime, null: true
  end
end
