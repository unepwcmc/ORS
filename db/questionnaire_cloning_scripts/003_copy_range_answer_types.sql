DROP FUNCTION IF EXISTS copy_range_answers_to_tmp(in_questionnaire_id INT);
CREATE FUNCTION copy_range_answers_to_tmp(in_questionnaire_id INT)
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
  WITH range_answers_to_copy AS (
    SELECT * FROM questionnaire_answer_types(in_questionnaire_id, 'RangeAnswer')
  )
  INSERT INTO tmp_range_answers (
    created_at,
    updated_at,
    original_id
  )
  SELECT
    current_timestamp,
    current_timestamp,
    range_answers.id
  FROM range_answers
  JOIN range_answers_to_copy t
  ON t.answer_type_id = range_answers.id;

  INSERT INTO tmp_range_answer_options (
    range_answer_id,
    sort_index,
    created_at,
    updated_at,
    original_id
  )
  SELECT
    tmp_range_answers.id,
    sort_index,
    tmp_range_answers.created_at,
    tmp_range_answers.updated_at,
    t.id
  FROM range_answer_options t
  JOIN tmp_range_answers
  ON tmp_range_answers.original_id = t.range_answer_id;

  INSERT INTO tmp_range_answer_option_fields (
    range_answer_option_id,
    option_text,
    language,
    is_default_language,
    created_at,
    updated_at
  )
  SELECT
    tmp_range_answer_options.id,
    option_text,
    language,
    is_default_language,
    tmp_range_answer_options.created_at,
    tmp_range_answer_options.updated_at
  FROM range_answer_option_fields t
  JOIN tmp_range_answer_options
  ON tmp_range_answer_options.original_id = t.range_answer_option_id;

  RETURN;
END;
$$
