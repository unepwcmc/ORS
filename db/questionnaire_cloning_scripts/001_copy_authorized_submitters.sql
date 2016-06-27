DROP FUNCTION IF EXISTS copy_authorized_submitters(
  old_questionnaire_id INTEGER, new_questionnaire_id INTEGER
);
CREATE OR REPLACE FUNCTION copy_authorized_submitters(
  old_questionnaire_id INTEGER, new_questionnaire_id INTEGER
) RETURNS VOID
LANGUAGE sql AS $$

  INSERT INTO authorized_submitters (
    user_id,
    questionnaire_id,
    status,
    language,
    total_questions,
    answered_questions,
    requested_unsubmission,
    created_at,
    updated_at
  )
  SELECT
    user_id,
    new_questionnaire_id,
    1, --underway
    language,
    total_questions,
    answered_questions,
    requested_unsubmission,
    current_timestamp,
    current_timestamp
  FROM authorized_submitters
  WHERE questionnaire_id = old_questionnaire_id;

$$
