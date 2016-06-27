class RemoveUnnecessaryTables < ActiveRecord::Migration
  def self.up
    execute <<-SQL
      DROP TABLE IF EXISTS new_answer_parts;
      DROP TABLE IF EXISTS new_answer_type_fields;
      DROP TABLE IF EXISTS new_answers;
      DROP TABLE IF EXISTS new_assignments;
      DROP TABLE IF EXISTS new_authorized_submitters;
      DROP TABLE IF EXISTS new_csv_files;
      DROP TABLE IF EXISTS new_documents;
      DROP TABLE IF EXISTS new_filtering_fields;
      DROP TABLE IF EXISTS new_loop_item_name_fields;
      DROP TABLE IF EXISTS new_loop_item_names;
      DROP TABLE IF EXISTS new_loop_item_types;
      DROP TABLE IF EXISTS new_loop_items;
      DROP TABLE IF EXISTS new_loop_sources;
      DROP TABLE IF EXISTS new_multi_answer_option_fields;
      DROP TABLE IF EXISTS new_multi_answer_options;
      DROP TABLE IF EXISTS new_multi_answers;
      DROP TABLE IF EXISTS new_numeric_answers;
      DROP TABLE IF EXISTS new_other_fields;
      DROP TABLE IF EXISTS new_pdf_files;
      DROP TABLE IF EXISTS new_question_fields;
      DROP TABLE IF EXISTS new_question_loop_types;
      DROP TABLE IF EXISTS new_questionnaire_fields;
      DROP TABLE IF EXISTS new_questionnaire_parts;
      DROP TABLE IF EXISTS new_questionnaires;
      DROP TABLE IF EXISTS new_questions;
      DROP TABLE IF EXISTS new_section_fields;
      DROP TABLE IF EXISTS new_sections;
      DROP TABLE IF EXISTS new_source_files;
      DROP TABLE IF EXISTS new_taggings;
      DROP TABLE IF EXISTS new_tags;
      DROP TABLE IF EXISTS new_text_answer_fields;
      DROP TABLE IF EXISTS new_text_answers;
      DROP TABLE IF EXISTS new_user_filtering_fields;
      DROP TABLE IF EXISTS new_user_section_submission_states;
      DROP TABLE IF EXISTS new_users;
    SQL
  end
end
