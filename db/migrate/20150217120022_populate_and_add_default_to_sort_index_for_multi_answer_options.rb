class PopulateAndAddDefaultToSortIndexForMultiAnswerOptions < ActiveRecord::Migration
  def change
    execute <<-SQL 
      UPDATE multi_answer_options AS m
      SET sort_index = t.rank
      FROM (
        SELECT id, rank()
        OVER (PARTITION BY multi_answer_id ORDER BY created_at ASC)
        FROM multi_answer_options
      ) AS t
     WHERE m.id = t.id
    SQL

    change_column :multi_answer_options, :sort_index, :integer, null: false, default: 0
  end
end
