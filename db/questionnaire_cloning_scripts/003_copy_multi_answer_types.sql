DROP FUNCTION IF EXISTS copy_multi_answers_to_tmp(in_questionnaire_id INT);
CREATE FUNCTION copy_multi_answers_to_tmp(in_questionnaire_id INT)
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
  WITH multi_answers_to_copy AS (
    SELECT * FROM questionnaire_answer_types(in_questionnaire_id, 'MultiAnswer')
  )
  INSERT INTO tmp_multi_answers (
    single,
    other_required,
    display_type,
    created_at,
    updated_at,
    original_id
  )
  SELECT
    single,
    other_required,
    display_type,
    multi_answers.created_at,
    current_timestamp,
    multi_answers.id
  FROM multi_answers
  JOIN multi_answers_to_copy t
  ON t.answer_type_id = multi_answers.id;

  INSERT INTO tmp_multi_answer_options (
    multi_answer_id,
    details_field,
    sort_index,
    created_at,
    updated_at,
    original_id
  )
  SELECT
    tmp_multi_answers.id,
    details_field,
    sort_index,
    tmp_multi_answers.created_at,
    tmp_multi_answers.updated_at,
    t.id
  FROM multi_answer_options t
  JOIN tmp_multi_answers
  ON tmp_multi_answers.original_id = t.multi_answer_id;

  INSERT INTO tmp_multi_answer_option_fields (
    multi_answer_option_id,
    option_text,
    language,
    is_default_language,
    created_at,
    updated_at
  )
  SELECT
    tmp_multi_answer_options.id,
    option_text,
    language,
    is_default_language,
    tmp_multi_answer_options.created_at,
    tmp_multi_answer_options.updated_at
  FROM multi_answer_option_fields t
  JOIN tmp_multi_answer_options
  ON tmp_multi_answer_options.original_id = t.multi_answer_option_id;

  INSERT INTO tmp_other_fields (
    multi_answer_id,
    other_text,
    language,
    is_default_language,
    created_at,
    updated_at
  )
  SELECT
    tmp_multi_answers.id,
    other_text,
    language,
    is_default_language,
    tmp_multi_answers.created_at,
    tmp_multi_answers.updated_at
  FROM other_fields
  JOIN tmp_multi_answers
  ON tmp_multi_answers.original_id = other_fields.multi_answer_id;
  RETURN;
END;
$$
