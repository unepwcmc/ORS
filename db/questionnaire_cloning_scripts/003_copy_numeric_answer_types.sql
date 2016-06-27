DROP FUNCTION IF EXISTS copy_numeric_answers_to_tmp(in_questionnaire_id INT);
CREATE FUNCTION copy_numeric_answers_to_tmp(in_questionnaire_id INT)
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
  WITH numeric_answers_to_copy AS (
    SELECT * FROM questionnaire_answer_types(in_questionnaire_id, 'NumericAnswer')
  )
  INSERT INTO tmp_numeric_answers (
    created_at,
    updated_at,
    original_id
  )
  SELECT
    current_timestamp,
    current_timestamp,
    numeric_answers.id
  FROM numeric_answers
  JOIN numeric_answers_to_copy t
  ON t.answer_type_id = numeric_answers.id;
  RETURN;
END;
$$;
