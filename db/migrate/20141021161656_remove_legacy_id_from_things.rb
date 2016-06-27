class RemoveLegacyIdFromThings < ActiveRecord::Migration
  def self.up
    execute 'ALTER TABLE questionnaires DROP COLUMN IF EXISTS legacy_id'
    execute 'ALTER TABLE questionnaire_fields DROP COLUMN IF EXISTS legacy_id'
    execute 'ALTER TABLE questionnaire_parts DROP COLUMN IF EXISTS legacy_id'
    execute 'ALTER TABLE sections DROP COLUMN IF EXISTS legacy_id'
    execute 'ALTER TABLE section_fields DROP COLUMN IF EXISTS legacy_id'
    execute 'ALTER TABLE questions DROP COLUMN IF EXISTS legacy_id'
    execute 'ALTER TABLE question_fields DROP COLUMN IF EXISTS legacy_id'
    execute 'ALTER TABLE question_loop_types DROP COLUMN IF EXISTS legacy_id'
    execute 'ALTER TABLE answers DROP COLUMN IF EXISTS legacy_id'
    execute 'ALTER TABLE answer_parts DROP COLUMN IF EXISTS legacy_id'
    execute 'ALTER TABLE answer_type_fields DROP COLUMN IF EXISTS legacy_id'
    execute 'ALTER TABLE multi_answer_option_fields DROP COLUMN IF EXISTS legacy_id'
    execute 'ALTER TABLE multi_answer_options DROP COLUMN IF EXISTS legacy_id'
    execute 'ALTER TABLE multi_answers DROP COLUMN IF EXISTS legacy_id'
    execute 'ALTER TABLE numeric_answers DROP COLUMN IF EXISTS legacy_id'
    execute 'ALTER TABLE text_answers DROP COLUMN IF EXISTS legacy_id'
    execute 'ALTER TABLE text_answer_fields DROP COLUMN IF EXISTS legacy_id'
    execute 'ALTER TABLE other_fields DROP COLUMN IF EXISTS legacy_id'
    execute 'ALTER TABLE loop_item_name_fields DROP COLUMN IF EXISTS legacy_id'
    execute 'ALTER TABLE loop_item_names DROP COLUMN IF EXISTS legacy_id'
    execute 'ALTER TABLE loop_item_types DROP COLUMN IF EXISTS legacy_id'
    execute 'ALTER TABLE loop_items DROP COLUMN IF EXISTS legacy_id'
    execute 'ALTER TABLE loop_sources DROP COLUMN IF EXISTS legacy_id'
    execute 'ALTER TABLE tags DROP COLUMN IF EXISTS legacy_id'
    execute 'ALTER TABLE taggings DROP COLUMN IF EXISTS legacy_id'
    execute 'ALTER TABLE csv_files DROP COLUMN IF EXISTS legacy_id'
    execute 'ALTER TABLE documents DROP COLUMN IF EXISTS legacy_id'
    execute 'ALTER TABLE filtering_fields DROP COLUMN IF EXISTS legacy_id'
    execute 'ALTER TABLE users DROP COLUMN IF EXISTS legacy_id'
    execute 'ALTER TABLE assignments DROP COLUMN IF EXISTS legacy_id'
    execute 'ALTER TABLE authorized_submitters DROP COLUMN IF EXISTS legacy_id'
    execute 'ALTER TABLE user_filtering_fields DROP COLUMN IF EXISTS legacy_id'
    execute 'ALTER TABLE user_section_submission_states DROP COLUMN IF EXISTS legacy_id'
    execute 'ALTER TABLE pdf_files DROP COLUMN IF EXISTS legacy_id'
    execute 'ALTER TABLE source_files DROP COLUMN IF EXISTS legacy_id'
  end

  def self.down
    add_column :questionnaires, :legacy_id, :integer
    add_column  :questionnaire_fields, :legacy_id, :integer
    add_column  :questionnaire_parts, :legacy_id, :integer
    add_column  :sections, :legacy_id, :integer
    add_column  :section_fields, :legacy_id, :integer
    add_column  :questions, :legacy_id, :integer
    add_column  :question_fields, :legacy_id, :integer
    add_column  :question_loop_types, :legacy_id, :integer
    add_column  :answers, :legacy_id, :integer
    add_column  :answer_parts, :legacy_id, :integer
    add_column  :answer_type_fields, :legacy_id, :integer
    add_column  :multi_answer_option_fields, :legacy_id, :integer
    add_column  :multi_answer_options, :legacy_id, :integer
    add_column  :multi_answers, :legacy_id, :integer
    add_column  :numeric_answers, :legacy_id, :integer
    add_column  :text_answers, :legacy_id, :integer
    add_column  :text_answer_fields, :legacy_id, :integer
    add_column  :other_fields, :legacy_id, :integer
    add_column  :loop_item_name_fields, :legacy_id, :integer
    add_column  :loop_item_names, :legacy_id, :integer
    add_column  :loop_item_types, :legacy_id, :integer
    add_column  :loop_items, :legacy_id, :integer
    add_column  :loop_sources, :legacy_id, :integer
    add_column  :tags, :legacy_id, :integer
    add_column  :taggings, :legacy_id, :integer
    add_column  :csv_files, :legacy_id, :integer
    add_column  :documents, :legacy_id, :integer
    add_column  :filtering_fields, :legacy_id, :integer
    add_column  :users, :legacy_id, :integer
    add_column  :assignments, :legacy_id, :integer
    add_column  :authorized_submitters, :legacy_id, :integer
    add_column  :user_filtering_fields, :legacy_id, :integer
    add_column  :user_section_submission_states, :legacy_id, :integer
    add_column  :pdf_files, :legacy_id, :integer
    add_column  :source_files, :legacy_id, :integer
  end
end
