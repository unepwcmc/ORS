DROP FUNCTION IF EXISTS copy_text_answers_to_tmp(in_questionnaire_id INT);
CREATE FUNCTION copy_text_answers_to_tmp(in_questionnaire_id INT)
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
  WITH text_answers_to_copy AS (
    SELECT * FROM questionnaire_answer_types(in_questionnaire_id, 'TextAnswer')
  )
  INSERT INTO tmp_text_answers (
    created_at,
    updated_at,
    original_id
  )
  SELECT
    current_timestamp,
    current_timestamp,
    text_answers.id
  FROM text_answers
  JOIN text_answers_to_copy t
  ON t.answer_type_id = text_answers.id;

  INSERT INTO tmp_text_answer_fields (
    text_answer_id,
    rows,
    width,
    created_at,
    updated_at,
    original_id
  )
  SELECT
    tmp_text_answers.id,
    rows,
    width,
    tmp_text_answers.created_at,
    tmp_text_answers.updated_at,
    t.id
  FROM text_answer_fields t
  JOIN tmp_text_answers
  ON tmp_text_answers.original_id = t.text_answer_id;

  RETURN;
END;
$$
