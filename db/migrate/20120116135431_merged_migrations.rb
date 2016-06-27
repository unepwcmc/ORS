class MergedMigrations < ActiveRecord::Migration
  def change
    create_table "alerts", :force => true do |t|
      t.integer  "deadline_id"
      t.integer  "reminder_id"
      t.datetime "created_at",  :null => false
      t.datetime "updated_at",  :null => false
    end

    create_table "answer_links", :force => true do |t|
      t.text     "url"
      t.text     "description"
      t.string   "title"
      t.integer  "answer_id"
      t.datetime "created_at",  :null => false
      t.datetime "updated_at",  :null => false
    end

    create_table "answer_part_matrix_options", :force => true do |t|
      t.integer  "answer_part_id"
      t.integer  "matrix_answer_option_id"
      t.datetime "created_at",                   :null => false
      t.datetime "updated_at",                   :null => false
      t.text     "answer_text"
      t.integer  "matrix_answer_drop_option_id"
    end

    create_table "answer_parts", :force => true do |t|
      t.text     "answer_text"
      t.integer  "answer_id"
      t.boolean  "deleted",                :default => false
      t.datetime "created_at",                                :null => false
      t.datetime "updated_at",                                :null => false
      t.string   "field_type_type"
      t.integer  "field_type_id"
      t.text     "details_text"
      t.text     "answer_text_in_english"
      t.string   "original_language"
      t.integer  "sort_index"
    end

    add_index "answer_parts", ["field_type_id"], :name => "index_answer_parts_on_field_type_id"

    create_table "answer_type_fields", :force => true do |t|
      t.string   "language"
      t.text     "help_text"
      t.datetime "created_at",                             :null => false
      t.datetime "updated_at",                             :null => false
      t.boolean  "is_default_language", :default => false
      t.string   "answer_type_type"
      t.integer  "answer_type_id"
    end

    create_table "answers", :force => true do |t|
      t.integer  "user_id"
      t.integer  "questionnaire_id"
      t.boolean  "deleted",                :default => false
      t.datetime "created_at",                                :null => false
      t.datetime "updated_at",                                :null => false
      t.text     "other_text"
      t.integer  "question_id"
      t.string   "looping_identifier"
      t.boolean  "from_dependent_section", :default => false
      t.integer  "last_editor_id"
      t.integer  "loop_item_id"
    end

    add_index "answers", ["question_id", "user_id", "looping_identifier"], :name => "index_answers_on_question_id_and_user_id_and_looping_identifier"

    create_table "assignments", :force => true do |t|
      t.integer  "user_id",    :null => false
      t.integer  "role_id",    :null => false
      t.datetime "created_at", :null => false
      t.datetime "updated_at", :null => false
    end

    create_table "authorized_submitters", :force => true do |t|
      t.integer  "user_id"
      t.integer  "questionnaire_id"
      t.datetime "created_at",                                :null => false
      t.datetime "updated_at",                                :null => false
      t.integer  "status",                 :default => 0
      t.string   "language",               :default => "en"
      t.integer  "total_questions",        :default => 0
      t.integer  "answered_questions",     :default => 0
      t.boolean  "requested_unsubmission", :default => false
    end

    create_table "csv_files", :force => true do |t|
      t.string   "name"
      t.string   "location"
      t.datetime "created_at",  :null => false
      t.datetime "updated_at",  :null => false
      t.string   "entity_type"
      t.integer  "entity_id"
    end

    create_table "deadlines", :force => true do |t|
      t.string   "title"
      t.boolean  "soft_deadline",    :default => false
      t.datetime "due_date"
      t.integer  "questionnaire_id"
      t.datetime "created_at",                          :null => false
      t.datetime "updated_at",                          :null => false
    end

    create_table "delegated_loop_item_names", :force => true do |t|
      t.integer  "loop_item_name_id"
      t.datetime "created_at",            :null => false
      t.datetime "updated_at",            :null => false
      t.integer  "delegation_section_id"
    end

    create_table "delegation_sections", :force => true do |t|
      t.integer  "delegation_id"
      t.integer  "section_id"
      t.datetime "created_at",    :null => false
      t.datetime "updated_at",    :null => false
    end

    create_table "delegations", :force => true do |t|
      t.datetime "created_at",       :null => false
      t.datetime "updated_at",       :null => false
      t.text     "remarks"
      t.integer  "questionnaire_id"
      t.integer  "user_delegate_id"
      t.boolean  "from_submission"
    end

    create_table "documents", :force => true do |t|
      t.integer  "answer_id"
      t.string   "doc_file_name"
      t.string   "doc_content_type"
      t.integer  "doc_file_size"
      t.datetime "doc_updated_at"
      t.datetime "created_at",       :null => false
      t.datetime "updated_at",       :null => false
      t.string   "description"
    end

    add_index "documents", ["answer_id"], :name => "index_documents_on_answer_id"

    create_table "extras", :force => true do |t|
      t.string   "name"
      t.integer  "loop_item_type_id"
      t.datetime "created_at",        :null => false
      t.datetime "updated_at",        :null => false
      t.integer  "field_type"
    end

    create_table "filtering_fields", :force => true do |t|
      t.string   "name"
      t.integer  "questionnaire_id"
      t.datetime "created_at",       :null => false
      t.datetime "updated_at",       :null => false
    end

    create_table "item_extra_fields", :force => true do |t|
      t.integer  "item_extra_id"
      t.string   "language",            :default => "en"
      t.string   "value"
      t.boolean  "is_default_language", :default => false
      t.datetime "created_at",                             :null => false
      t.datetime "updated_at",                             :null => false
    end

    create_table "item_extras", :force => true do |t|
      t.integer  "loop_item_name_id"
      t.integer  "extra_id"
      t.datetime "created_at",        :null => false
      t.datetime "updated_at",        :null => false
    end

    create_table "loop_item_name_fields", :force => true do |t|
      t.string   "language"
      t.string   "item_name"
      t.boolean  "is_default_language"
      t.integer  "loop_item_name_id"
      t.datetime "created_at",          :null => false
      t.datetime "updated_at",          :null => false
    end

    create_table "loop_item_names", :force => true do |t|
      t.integer  "loop_source_id"
      t.integer  "loop_item_type_id"
      t.datetime "created_at",        :null => false
      t.datetime "updated_at",        :null => false
    end

    create_table "loop_item_types", :force => true do |t|
      t.string   "name"
      t.integer  "parent_id"
      t.integer  "lft"
      t.integer  "rgt"
      t.integer  "loop_source_id"
      t.datetime "created_at",         :null => false
      t.datetime "updated_at",         :null => false
      t.integer  "filtering_field_id"
    end

    create_table "loop_items", :force => true do |t|
      t.boolean  "deleted",           :default => false
      t.integer  "parent_id"
      t.integer  "lft"
      t.integer  "rgt"
      t.datetime "created_at",                           :null => false
      t.datetime "updated_at",                           :null => false
      t.integer  "loop_item_type_id"
      t.integer  "sort_index",        :default => 0
      t.integer  "loop_item_name_id"
    end

    create_table "loop_sources", :force => true do |t|
      t.string   "name"
      t.boolean  "deleted",          :default => false
      t.integer  "questionnaire_id"
      t.datetime "created_at",                          :null => false
      t.datetime "updated_at",                          :null => false
    end

    create_table "matrix_answer_drop_option_fields", :force => true do |t|
      t.integer  "matrix_answer_drop_option_id"
      t.string   "language"
      t.boolean  "is_default_language"
      t.string   "option_text"
      t.datetime "created_at",                   :null => false
      t.datetime "updated_at",                   :null => false
    end

    create_table "matrix_answer_drop_options", :force => true do |t|
      t.integer  "matrix_answer_id"
      t.datetime "created_at",       :null => false
      t.datetime "updated_at",       :null => false
    end

    create_table "matrix_answer_option_fields", :force => true do |t|
      t.integer  "matrix_answer_option_id"
      t.string   "language"
      t.text     "title"
      t.boolean  "is_default_language"
      t.datetime "created_at",              :null => false
      t.datetime "updated_at",              :null => false
    end

    create_table "matrix_answer_options", :force => true do |t|
      t.integer  "matrix_answer_id"
      t.datetime "created_at",       :null => false
      t.datetime "updated_at",       :null => false
    end

    create_table "matrix_answer_queries", :force => true do |t|
      t.integer  "matrix_answer_id"
      t.datetime "created_at",       :null => false
      t.datetime "updated_at",       :null => false
    end

    create_table "matrix_answer_query_fields", :force => true do |t|
      t.integer  "matrix_answer_query_id"
      t.string   "language"
      t.text     "title"
      t.boolean  "is_default_language"
      t.datetime "created_at",             :null => false
      t.datetime "updated_at",             :null => false
    end

    create_table "matrix_answers", :force => true do |t|
      t.integer  "display_reply"
      t.datetime "created_at",         :null => false
      t.datetime "updated_at",         :null => false
      t.integer  "matrix_orientation"
    end

    create_table "multi_answer_option_fields", :force => true do |t|
      t.string   "language"
      t.text     "option_text"
      t.integer  "multi_answer_option_id"
      t.datetime "created_at",                                :null => false
      t.datetime "updated_at",                                :null => false
      t.boolean  "is_default_language",    :default => false
    end

    add_index "multi_answer_option_fields", ["language"], :name => "index_multi_answer_option_fields_on_language"

    create_table "multi_answer_options", :force => true do |t|
      t.integer  "multi_answer_id"
      t.datetime "created_at",                         :null => false
      t.datetime "updated_at",                         :null => false
      t.boolean  "deleted",         :default => false
      t.boolean  "details_field",   :default => false
    end

    create_table "multi_answers", :force => true do |t|
      t.boolean  "single",         :default => true
      t.datetime "created_at",                        :null => false
      t.datetime "updated_at",                        :null => false
      t.boolean  "deleted",        :default => false
      t.boolean  "other_required", :default => false
      t.integer  "display_type"
    end

    create_table "numeric_answers", :force => true do |t|
      t.integer  "max_value"
      t.integer  "min_value"
      t.datetime "created_at", :null => false
      t.datetime "updated_at", :null => false
    end

    create_table "other_fields", :force => true do |t|
      t.string   "language"
      t.text     "other_text"
      t.integer  "multi_answer_id"
      t.boolean  "is_default_language"
      t.datetime "created_at",          :null => false
      t.datetime "updated_at",          :null => false
    end

    create_table "pdf_files", :force => true do |t|
      t.integer  "questionnaire_id"
      t.integer  "user_id"
      t.string   "name"
      t.string   "location"
      t.datetime "created_at",                         :null => false
      t.datetime "updated_at",                         :null => false
      t.boolean  "is_long",          :default => true
    end

    create_table "persistent_errors", :force => true do |t|
      t.string   "title"
      t.text     "details"
      t.datetime "timestamp"
      t.integer  "user_id"
      t.string   "errorable_type"
      t.integer  "errorable_id"
      t.string   "user_ip"
      t.datetime "created_at",     :null => false
      t.datetime "updated_at",     :null => false
    end

    create_table "question_extras", :force => true do |t|
      t.integer  "question_id"
      t.integer  "extra_id"
      t.datetime "created_at",  :null => false
      t.datetime "updated_at",  :null => false
    end

    create_table "question_fields", :force => true do |t|
      t.string   "language"
      t.text     "title"
      t.string   "short_title"
      t.text     "description"
      t.integer  "question_id"
      t.datetime "created_at",                             :null => false
      t.datetime "updated_at",                             :null => false
      t.boolean  "is_default_language", :default => false
    end

    add_index "question_fields", ["question_id", "language"], :name => "index_question_fields_on_question_id_and_language"

    create_table "question_loop_types", :force => true do |t|
      t.integer  "question_id"
      t.integer  "loop_item_type_id"
      t.datetime "created_at",        :null => false
      t.datetime "updated_at",        :null => false
    end

    create_table "questionnaire_fields", :force => true do |t|
      t.string   "language"
      t.text     "title"
      t.integer  "questionnaire_id"
      t.datetime "created_at",                                                                 :null => false
      t.datetime "updated_at",                                                                 :null => false
      t.text     "introductory_remarks"
      t.boolean  "is_default_language",  :default => false
      t.string   "email_subject",        :default => "[CMS Family - Online Reporting System]"
      t.text     "email"
      t.string   "email_footer"
      t.text     "submit_info_tip"
    end

    create_table "questionnaire_parts", :force => true do |t|
      t.integer  "questionnaire_id"
      t.integer  "part_id"
      t.string   "part_type"
      t.datetime "created_at",       :null => false
      t.datetime "updated_at",       :null => false
      t.integer  "parent_id"
      t.integer  "lft"
      t.integer  "rgt"
    end

    create_table "questionnaires", :force => true do |t|
      t.boolean  "deleted",                  :default => false
      t.datetime "created_at",                                  :null => false
      t.datetime "updated_at",                                  :null => false
      t.datetime "last_edited"
      t.integer  "user_id"
      t.integer  "last_editor_id"
      t.datetime "activated_at"
      t.text     "administrator_remarks"
      t.date     "questionnaire_date"
      t.string   "header_file_name"
      t.string   "header_content_type"
      t.integer  "header_file_size"
      t.datetime "header_updated_at"
      t.integer  "status",                   :default => 0
      t.integer  "source_questionnaire_id"
      t.string   "display_in_tab_max_level", :default => "3"
      t.boolean  "delegation_enabled",       :default => true
      t.string   "help_pages"
      t.boolean  "translator_visible",       :default => false
      t.boolean  "private_documents",        :default => true
    end

    create_table "questions", :force => true do |t|
      t.string   "uidentifier"
      t.integer  "type"
      t.boolean  "deleted",          :default => false
      t.datetime "last_edited"
      t.integer  "number"
      t.integer  "section_id"
      t.integer  "answer_type_id"
      t.string   "answer_type_type"
      t.datetime "created_at",                          :null => false
      t.datetime "updated_at",                          :null => false
      t.boolean  "is_mandatory",     :default => false
      t.integer  "ordering"
    end

    create_table "range_answer_option_fields", :force => true do |t|
      t.integer  "range_answer_option_id"
      t.string   "option_text"
      t.string   "language"
      t.datetime "created_at",             :null => false
      t.datetime "updated_at",             :null => false
      t.boolean  "is_default_language"
    end

    create_table "range_answer_options", :force => true do |t|
      t.integer  "range_answer_id"
      t.integer  "sort_index"
      t.datetime "created_at",      :null => false
      t.datetime "updated_at",      :null => false
    end

    create_table "range_answers", :force => true do |t|
      t.datetime "created_at", :null => false
      t.datetime "updated_at", :null => false
    end

    create_table "rank_answer_option_fields", :force => true do |t|
      t.integer  "rank_answer_option_id"
      t.string   "language"
      t.text     "option_text"
      t.boolean  "is_default_language"
      t.datetime "created_at",            :null => false
      t.datetime "updated_at",            :null => false
    end

    create_table "rank_answer_options", :force => true do |t|
      t.integer  "rank_answer_id"
      t.datetime "created_at",     :null => false
      t.datetime "updated_at",     :null => false
    end

    create_table "rank_answers", :force => true do |t|
      t.integer  "maximum_choices", :default => -1
      t.datetime "created_at",                      :null => false
      t.datetime "updated_at",                      :null => false
    end

    create_table "reminders", :force => true do |t|
      t.string   "title"
      t.text     "body"
      t.datetime "created_at", :null => false
      t.datetime "updated_at", :null => false
      t.integer  "days"
    end

    create_table "roles", :force => true do |t|
      t.string   "name"
      t.datetime "created_at", :null => false
      t.datetime "updated_at", :null => false
    end

    create_table "section_extras", :force => true do |t|
      t.integer  "section_id"
      t.integer  "extra_id"
      t.datetime "created_at", :null => false
      t.datetime "updated_at", :null => false
    end

    create_table "section_fields", :force => true do |t|
      t.text     "title"
      t.string   "language"
      t.text     "description"
      t.integer  "section_id"
      t.datetime "created_at",                             :null => false
      t.datetime "updated_at",                             :null => false
      t.boolean  "is_default_language", :default => false
      t.text     "tab_title"
    end

    add_index "section_fields", ["section_id", "language"], :name => "index_section_fields_on_section_id_and_language"

    create_table "sections", :force => true do |t|
      t.boolean  "deleted",                 :default => false
      t.datetime "created_at",                                 :null => false
      t.datetime "updated_at",                                 :null => false
      t.datetime "last_edited"
      t.integer  "section_type"
      t.integer  "answer_type_id"
      t.string   "answer_type_type"
      t.integer  "loop_source_id"
      t.integer  "loop_item_type_id"
      t.integer  "depends_on_option_id"
      t.boolean  "depends_on_option_value", :default => true
      t.integer  "depends_on_question_id"
      t.boolean  "is_hidden",               :default => false
      t.boolean  "starts_collapsed",        :default => false
      t.boolean  "display_in_tab",          :default => false
    end

    add_index "sections", ["depends_on_question_id"], :name => "index_sections_on_depends_on_question_id"
    add_index "sections", ["loop_item_type_id"], :name => "index_sections_on_loop_item_type_id"

    create_table "source_files", :force => true do |t|
      t.integer  "loop_source_id"
      t.string   "source_file_name"
      t.string   "source_content_type"
      t.integer  "source_file_size"
      t.datetime "source_updated_at"
      t.datetime "created_at",                         :null => false
      t.datetime "updated_at",                         :null => false
      t.integer  "parse_status",        :default => 0
    end

    create_table "taggings", :force => true do |t|
      t.integer  "tag_id"
      t.integer  "taggable_id"
      t.integer  "tagger_id"
      t.string   "tagger_type"
      t.string   "taggable_type"
      t.string   "context"
      t.datetime "created_at"
    end

    add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"
    add_index "taggings", ["taggable_id", "taggable_type", "context"], :name => "index_taggings_on_taggable_id_and_taggable_type_and_context"

    create_table "tags", :force => true do |t|
      t.string "name"
    end

    create_table "text_answer_fields", :force => true do |t|
      t.integer  "text_answer_id"
      t.integer  "rows"
      t.integer  "width"
      t.datetime "created_at",                        :null => false
      t.datetime "updated_at",                        :null => false
      t.boolean  "deleted",        :default => false
    end

    create_table "text_answers", :force => true do |t|
      t.datetime "created_at",                    :null => false
      t.datetime "updated_at",                    :null => false
      t.boolean  "deleted",    :default => false
    end

    create_table "user_delegates", :force => true do |t|
      t.integer  "user_id"
      t.integer  "delegate_id"
      t.string   "details"
      t.datetime "created_at",                 :null => false
      t.datetime "updated_at",                 :null => false
      t.integer  "state",       :default => 0
    end

    create_table "user_filtering_fields", :force => true do |t|
      t.integer  "user_id"
      t.datetime "created_at",         :null => false
      t.datetime "updated_at",         :null => false
      t.integer  "filtering_field_id"
      t.string   "field_value"
    end

    create_table "user_section_submission_states", :force => true do |t|
      t.integer  "user_id",                               :null => false
      t.datetime "created_at",                            :null => false
      t.datetime "updated_at",                            :null => false
      t.integer  "section_state",      :default => 4
      t.integer  "section_id"
      t.string   "looping_identifier"
      t.integer  "loop_item_id"
      t.boolean  "dont_care",          :default => false
    end

    create_table "users", :force => true do |t|
      t.string   "email",                                 :null => false
      t.string   "persistence_token",                     :null => false
      t.string   "crypted_password",                      :null => false
      t.string   "password_salt",                         :null => false
      t.datetime "created_at",                            :null => false
      t.datetime "updated_at",                            :null => false
      t.integer  "login_count",         :default => 0,    :null => false
      t.integer  "failed_login_count",  :default => 0,    :null => false
      t.datetime "last_request_at"
      t.datetime "current_login_at"
      t.datetime "last_login_at"
      t.string   "current_login_ip"
      t.string   "last_login_ip"
      t.string   "perishable_token",                      :null => false
      t.string   "single_access_token",                   :null => false
      t.string   "first_name"
      t.string   "last_name"
      t.integer  "creator_id",          :default => 0
      t.string   "language",            :default => "en"
    end
  end
end
