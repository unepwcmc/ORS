DROP FUNCTION IF EXISTS copy_matrix_answers_to_tmp(in_questionnaire_id INT);
CREATE FUNCTION copy_matrix_answers_to_tmp(in_questionnaire_id INT)
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
  WITH matrix_answers_to_copy AS (
    SELECT * FROM questionnaire_answer_types(in_questionnaire_id, 'MatrixAnswer')
  )
  INSERT INTO tmp_matrix_answers (
    display_reply,
    matrix_orientation,
    created_at,
    updated_at,
    original_id
  )
  SELECT
    display_reply,
    matrix_orientation,
    current_timestamp,
    current_timestamp,
    matrix_answers.id
  FROM matrix_answers
  JOIN matrix_answers_to_copy t
  ON t.answer_type_id = matrix_answers.id;

  WITH copied_matrix_answer_options AS (
    INSERT INTO tmp_matrix_answer_options (
      matrix_answer_id,
      created_at,
      updated_at,
      original_id
    )
    SELECT
      tmp_matrix_answers.id,
      current_timestamp,
      current_timestamp,
      t.id
    FROM matrix_answer_options t
    JOIN tmp_matrix_answers
    ON tmp_matrix_answers.original_id = t.matrix_answer_id
    RETURNING *
  )
  INSERT INTO tmp_matrix_answer_option_fields (
    matrix_answer_option_id,
    language,
    title,
    is_default_language,
    created_at,
    updated_at
  )
  SELECT
    copied_matrix_answer_options.id,
    language,
    title,
    is_default_language,
    current_timestamp,
    current_timestamp
  FROM matrix_answer_option_fields t
  JOIN copied_matrix_answer_options
  ON copied_matrix_answer_options.original_id = t.matrix_answer_option_id;

  WITH copied_matrix_answer_drop_options AS (
    INSERT INTO tmp_matrix_answer_drop_options (
      matrix_answer_id,
      created_at,
      updated_at,
      original_id
    )
    SELECT
      tmp_matrix_answers.id,
      current_timestamp,
      current_timestamp,
      t.id
    FROM matrix_answer_drop_options t
    JOIN tmp_matrix_answers
    ON tmp_matrix_answers.original_id = t.matrix_answer_id
    RETURNING *
  )
  INSERT INTO tmp_matrix_answer_drop_option_fields (
    matrix_answer_drop_option_id,
    language,
    is_default_language,
    option_text,
    created_at,
    updated_at
  )
  SELECT
    copied_matrix_answer_drop_options.id,
    language,
    is_default_language,
    option_text,
    current_timestamp,
    current_timestamp
  FROM matrix_answer_drop_option_fields t
  JOIN copied_matrix_answer_drop_options
  ON copied_matrix_answer_drop_options.original_id = t.matrix_answer_drop_option_id;

  INSERT INTO tmp_matrix_answer_queries (
    matrix_answer_id,
    created_at,
    updated_at,
    original_id
  )
  SELECT
    tmp_matrix_answers.id,
    current_timestamp,
    current_timestamp,
    t.id
  FROM matrix_answer_queries t
  JOIN tmp_matrix_answers
  ON tmp_matrix_answers.original_id = t.matrix_answer_id;

  INSERT INTO tmp_matrix_answer_query_fields (
    matrix_answer_query_id,
    language,
    title,
    is_default_language,
    created_at,
    updated_at
  )
  SELECT
    tmp_matrix_answer_queries.id,
    language,
    title,
    is_default_language,
    current_timestamp,
    current_timestamp
  FROM matrix_answer_query_fields t
  JOIN tmp_matrix_answer_queries
  ON tmp_matrix_answer_queries.original_id = t.matrix_answer_query_id;

  RETURN;
END;
$$
