DROP FUNCTION IF EXISTS copy_answer_types_start(
  old_questionnaire_id INTEGER
);
CREATE OR REPLACE FUNCTION copy_answer_types_start(
  old_questionnaire_id INTEGER
) RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
  -- create temp tables to hold answer types for the duration of the cloning
  CREATE TEMP TABLE tmp_text_answers () INHERITS (text_answers);
  CREATE TEMP TABLE tmp_text_answer_fields () INHERITS (text_answer_fields);
  PERFORM copy_text_answers_to_tmp(old_questionnaire_id);
  CREATE TEMP TABLE tmp_numeric_answers () INHERITS (numeric_answers);
  PERFORM copy_numeric_answers_to_tmp(old_questionnaire_id);
  CREATE TEMP TABLE tmp_rank_answers () INHERITS (rank_answers);
  CREATE TEMP TABLE tmp_rank_answer_options () INHERITS (rank_answer_options);
  CREATE TEMP TABLE tmp_rank_answer_option_fields () INHERITS (rank_answer_option_fields);
  PERFORM copy_rank_answers_to_tmp(old_questionnaire_id);
  CREATE TEMP TABLE tmp_range_answers () INHERITS (range_answers);
  CREATE TEMP TABLE tmp_range_answer_options () INHERITS (range_answer_options);
  CREATE TEMP TABLE tmp_range_answer_option_fields () INHERITS (range_answer_option_fields);
  PERFORM copy_range_answers_to_tmp(old_questionnaire_id);
  CREATE TEMP TABLE tmp_multi_answers () INHERITS (multi_answers);
  CREATE TEMP TABLE tmp_multi_answer_options () INHERITS (multi_answer_options);
  CREATE TEMP TABLE tmp_multi_answer_option_fields () INHERITS (multi_answer_option_fields);
  CREATE TEMP TABLE tmp_other_fields () INHERITS (other_fields);
  PERFORM copy_multi_answers_to_tmp(old_questionnaire_id);
  CREATE TEMP TABLE tmp_matrix_answers () INHERITS (matrix_answers);
  CREATE TEMP TABLE tmp_matrix_answer_options () INHERITS (matrix_answer_options);
  CREATE TEMP TABLE tmp_matrix_answer_option_fields () INHERITS (matrix_answer_option_fields);
  CREATE TEMP TABLE tmp_matrix_answer_drop_options () INHERITS (matrix_answer_drop_options);
  CREATE TEMP TABLE tmp_matrix_answer_drop_option_fields () INHERITS (matrix_answer_drop_option_fields);
  CREATE TEMP TABLE tmp_matrix_answer_queries () INHERITS (matrix_answer_queries);
  CREATE TEMP TABLE tmp_matrix_answer_query_fields () INHERITS (matrix_answer_query_fields);
  PERFORM copy_matrix_answers_to_tmp(old_questionnaire_id);

  WITH answer_type_fields_with_resolved_ids AS (
    SELECT t.*, tmp_text_answers.id AS new_answer_type_id
    FROM tmp_text_answers
    JOIN answer_type_fields t
    ON t.answer_type_type = 'TextAnswer'
    AND t.answer_type_id = tmp_text_answers.original_id

    UNION

    SELECT t.*, tmp_numeric_answers.id AS new_answer_type_id
    FROM tmp_numeric_answers
    JOIN answer_type_fields t
    ON t.answer_type_type = 'NumericAnswer'
    AND t.answer_type_id = tmp_numeric_answers.original_id

    UNION

    SELECT t.*, tmp_rank_answers.id AS new_answer_type_id
    FROM tmp_rank_answers
    JOIN answer_type_fields t
    ON t.answer_type_type = 'RankAnswer'
    AND t.answer_type_id = tmp_rank_answers.original_id

    UNION

    SELECT t.*, tmp_range_answers.id AS new_answer_type_id
    FROM tmp_range_answers
    JOIN answer_type_fields t
    ON t.answer_type_type = 'RangeAnswer'
    AND t.answer_type_id = tmp_range_answers.original_id

    UNION

    SELECT t.*, tmp_multi_answers.id AS new_answer_type_id
    FROM tmp_multi_answers
    JOIN answer_type_fields t
    ON t.answer_type_type = 'MultiAnswer'
    AND t.answer_type_id = tmp_multi_answers.original_id

    UNION

    SELECT t.*, tmp_matrix_answers.id AS new_answer_type_id
    FROM tmp_matrix_answers
    JOIN answer_type_fields t
    ON t.answer_type_type = 'MatrixAnswer'
    AND t.answer_type_id = tmp_matrix_answers.original_id
  )
  INSERT INTO answer_type_fields (
    answer_type_type,
    answer_type_id,
    language,
    is_default_language,
    help_text,
    created_at,
    updated_at
  )
  SELECT
    answer_type_type,
    new_answer_type_id,
    language,
    is_default_language,
    help_text,
    current_timestamp,
    current_timestamp
  FROM answer_type_fields_with_resolved_ids;

  RETURN;
END;
$$;

DROP FUNCTION IF EXISTS copy_answer_types_end();
CREATE OR REPLACE FUNCTION copy_answer_types_end()
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO text_answers SELECT * FROM tmp_text_answers;
  DROP TABLE tmp_text_answers;
  INSERT INTO text_answer_fields SELECT * FROM tmp_text_answer_fields;
  DROP TABLE tmp_text_answer_fields;
  INSERT INTO numeric_answers SELECT * FROM tmp_numeric_answers;
  DROP TABLE tmp_numeric_answers;
  INSERT INTO rank_answers SELECT * FROM tmp_rank_answers;
  DROP TABLE tmp_rank_answers;
  INSERT INTO rank_answer_options SELECT * FROM tmp_rank_answer_options;
  DROP TABLE tmp_rank_answer_options;
  INSERT INTO rank_answer_option_fields SELECT * FROM tmp_rank_answer_option_fields;
  DROP TABLE tmp_rank_answer_option_fields;
  INSERT INTO range_answers SELECT * FROM tmp_range_answers;
  DROP TABLE tmp_range_answers;
  INSERT INTO range_answer_options SELECT * FROM tmp_range_answer_options;
  DROP TABLE tmp_range_answer_options;
  INSERT INTO range_answer_option_fields SELECT * FROM tmp_range_answer_option_fields;
  DROP TABLE tmp_range_answer_option_fields;
  INSERT INTO multi_answers SELECT * FROM tmp_multi_answers;
  DROP TABLE tmp_multi_answers;
  INSERT INTO multi_answer_options SELECT * FROM tmp_multi_answer_options;
  DROP TABLE tmp_multi_answer_options;
  INSERT INTO multi_answer_option_fields SELECT * FROM tmp_multi_answer_option_fields;
  DROP TABLE tmp_multi_answer_option_fields;
  INSERT INTO tmp_other_fields SELECT * FROM tmp_other_fields;
  DROP TABLE tmp_other_fields;
  INSERT INTO matrix_answers SELECT * FROM tmp_matrix_answers;
  DROP TABLE tmp_matrix_answers;
  INSERT INTO matrix_answer_options SELECT * FROM tmp_matrix_answer_options;
  DROP TABLE tmp_matrix_answer_options;
  INSERT INTO matrix_answer_option_fields SELECT * FROM tmp_matrix_answer_option_fields;
  DROP TABLE tmp_matrix_answer_option_fields;
  INSERT INTO matrix_answer_drop_options SELECT * FROM tmp_matrix_answer_drop_options;
  DROP TABLE tmp_matrix_answer_drop_options;
  INSERT INTO matrix_answer_drop_option_fields SELECT * FROM tmp_matrix_answer_drop_option_fields;
  DROP TABLE tmp_matrix_answer_drop_option_fields;
  INSERT INTO matrix_answer_queries SELECT * FROM tmp_matrix_answer_queries;
  DROP TABLE tmp_matrix_answer_queries;
  INSERT INTO matrix_answer_query_fields SELECT * FROM tmp_matrix_answer_query_fields;
  DROP TABLE tmp_matrix_answer_query_fields;
  RETURN;
END;
$$;
