class AddConstraintsToMultiAnswerOptions < ActiveRecord::Migration
  def up
    # if API views already in place, need to drop before changing columns
    if ActiveRecord::Base.connection.table_exists? 'api_multi_answer_options_view'
      drop_view_and_dependent_views
      re_create_view = true
    end

    # make multi_answer_id NOT NULL & add foreign key constraint
    add_index :multi_answer_options, :multi_answer_id
    execute <<-SQL
      DELETE FROM multi_answer_options
      WHERE id IN (
        SELECT mao.id
        FROM multi_answer_options AS mao
        LEFT OUTER JOIN multi_answers AS ma ON mao.multi_answer_id = ma.id
        WHERE ma.id IS NULL OR mao.multi_answer_id IS NULL
      )
    SQL

    change_column :multi_answer_options,
      :multi_answer_id, :integer, null: false
    add_foreign_key :multi_answer_options,
      :multi_answers, {
        column: :multi_answer_id,
        dependent: :delete
      }

    # make timestamps NOT NULL
    execute "UPDATE multi_answer_options SET created_at = NOW() WHERE created_at IS NULL"
    change_column :multi_answer_options, :created_at, :datetime, null: false
    execute "UPDATE multi_answer_options SET updated_at = NOW() WHERE updated_at IS NULL"
    change_column :multi_answer_options, :updated_at, :datetime, null: false

    # re-create the view if necessary
    create_view_and_dependent_views if re_create_view
  end

  def down
    # if API views already in place, need to drop before changing columns
    if ActiveRecord::Base.connection.table_exists? 'api_multi_answer_options_view'
      drop_view_and_dependent_views
      re_create_view = true
    end

    remove_index :multi_answer_options, :multi_answer_id
    change_column :multi_answer_options,
      :multi_answer_id, :integer, null: true
    remove_foreign_key :multi_answer_options, column: :multi_answer_id

    change_column :multi_answer_options,
      :created_at, :datetime, null: true
    change_column :multi_answer_options,
      :updated_at, :datetime, null: true

    # re-create the view if necessary
    create_view_and_dependent_views if re_create_view
  end

  def drop_view_and_dependent_views
    execute 'DROP VIEW api_answers_view'
    execute 'DROP VIEW api_questions_tree_view'
    execute 'DROP VIEW api_multi_answer_options_view'
  end

  def create_view_and_dependent_views
    execute view_sql('20151030151237', 'api_multi_answer_options_view')
    execute view_sql('20160202174508', 'api_questions_tree_view')
    execute view_sql('20160203162148', 'api_answers_view')
  end
end
