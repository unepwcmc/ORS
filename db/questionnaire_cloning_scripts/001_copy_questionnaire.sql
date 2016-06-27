DROP FUNCTION IF EXISTS copy_questionnaire(
  in_questionnaire_id INTEGER, in_user_id INTEGER
);
CREATE OR REPLACE FUNCTION copy_questionnaire(
  in_questionnaire_id INTEGER, in_user_id INTEGER
) RETURNS INTEGER
LANGUAGE sql AS $$
  WITH copied_questionnaires AS (
    INSERT INTO questionnaires (
      user_id,
      last_editor_id,
      administrator_remarks,
      questionnaire_date,
      header_file_name,
      header_content_type,
      header_file_size,
      header_updated_at,
      status,
      display_in_tab_max_level,
      delegation_enabled,
      help_pages,
      translator_visible,
      private_documents,
      created_at,
      updated_at,
      activated_at,
      last_edited,
      original_id
    )
    SELECT
      in_user_id,
      in_user_id,
      administrator_remarks,
      questionnaire_date,
      header_file_name,
      header_content_type,
      header_file_size,
      header_updated_at,
      0, -- not started
      display_in_tab_max_level,
      delegation_enabled,
      help_pages,
      translator_visible,
      private_documents,
      current_timestamp,
      current_timestamp,
      NULL,
      NULL,
      id
    FROM questionnaires
    WHERE id = in_questionnaire_id
    RETURNING *
  ), copied_questionnaire_fields AS (
    INSERT INTO questionnaire_fields (
      questionnaire_id,
      language,
      title,
      introductory_remarks,
      is_default_language,
      email_subject,
      email,
      email_footer,
      submit_info_tip,
      created_at,
      updated_at
    )
    SELECT
      copied_questionnaires.id,
      t.language,
      'COPY ' || TO_CHAR(copied_questionnaires.created_at, 'DD/MM/YYYY') || ': ' || t.title,
      t.introductory_remarks,
      t.is_default_language,
      t.email_subject,
      t.email,
      t.email_footer,
      t.submit_info_tip,
      copied_questionnaires.created_at,
      copied_questionnaires.updated_at
    FROM questionnaire_fields t
    JOIN copied_questionnaires
    ON copied_questionnaires.original_id = t.questionnaire_id
  )
  SELECT id FROM copied_questionnaires;
$$;
