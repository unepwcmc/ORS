DROP FUNCTION IF EXISTS copy_rank_answers_to_tmp(in_questionnaire_id INT);
CREATE FUNCTION copy_rank_answers_to_tmp(in_questionnaire_id INT)
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
  WITH rank_answers_to_copy AS (
    SELECT * FROM questionnaire_answer_types(in_questionnaire_id, 'RankAnswer')
  )
  INSERT INTO tmp_rank_answers (
    maximum_choices,
    created_at,
    updated_at,
    original_id
  )
  SELECT
    maximum_choices,
    current_timestamp,
    current_timestamp,
    rank_answers.id
  FROM rank_answers
  JOIN rank_answers_to_copy t
  ON t.answer_type_id = rank_answers.id;

  INSERT INTO tmp_rank_answer_options (
    rank_answer_id,
    created_at,
    updated_at,
    original_id
  )
  SELECT
    tmp_rank_answers.id,
    tmp_rank_answers.created_at,
    tmp_rank_answers.updated_at,
    t.id
  FROM rank_answer_options t
  JOIN tmp_rank_answers
  ON tmp_rank_answers.original_id = t.rank_answer_id;

  INSERT INTO tmp_rank_answer_option_fields (
    rank_answer_option_id,
    language,
    option_text,
    is_default_language,
    created_at,
    updated_at
  )
  SELECT
    tmp_rank_answer_options.id,
    language,
    option_text,
    is_default_language,
    tmp_rank_answer_options.created_at,
    tmp_rank_answer_options.updated_at
  FROM rank_answer_option_fields t
  JOIN tmp_rank_answer_options
  ON tmp_rank_answer_options.original_id = t.rank_answer_option_id;

  RETURN;
END;
$$
