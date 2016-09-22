DROP FUNCTION IF EXISTS copy_answer_parts(
  old_questionnaire_id INTEGER, new_questionnaire_id INTEGER
);
DROP FUNCTION IF EXISTS copy_answer_parts_start(
  old_questionnaire_id INTEGER, new_questionnaire_id INTEGER
);
CREATE OR REPLACE FUNCTION copy_answer_parts_start(
  old_questionnaire_id INTEGER, new_questionnaire_id INTEGER
) RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
  CREATE TEMP TABLE tmp_answer_parts () INHERITS (answer_parts);
  CREATE TEMP TABLE tmp_answer_part_matrix_options () INHERITS (answer_part_matrix_options);

  WITH answer_parts_to_copy AS (
    SELECT
      answer_parts.*,
      tmp_answers.id AS new_answer_id,
      tmp_answers.created_at AS new_created_at,
      tmp_answers.updated_at AS new_updated_at
    FROM answer_parts
    JOIN tmp_answers
    ON tmp_answers.original_id = answer_parts.answer_id
  ), answer_parts_to_copy_with_resolved_field_types AS (
    SELECT answer_parts_to_copy.*, fields.id AS new_field_type_id
    FROM answer_parts_to_copy
    JOIN tmp_text_answer_fields fields
    ON answer_parts_to_copy.field_type_type = 'TextAnswerField'
    AND fields.original_id = answer_parts_to_copy.field_type_id

    UNION

    SELECT answer_parts_to_copy.*, fields.id AS new_field_type_id
    FROM answer_parts_to_copy
    JOIN tmp_numeric_answers fields
    ON answer_parts_to_copy.field_type_type = 'NumericAnswer'
    AND fields.original_id = answer_parts_to_copy.field_type_id

    UNION

    SELECT answer_parts_to_copy.*, fields.id AS new_field_type_id
    FROM answer_parts_to_copy
    JOIN tmp_rank_answer_options fields
    ON answer_parts_to_copy.field_type_type = 'RankAnswerOption'
    AND fields.original_id = answer_parts_to_copy.field_type_id

    UNION

    SELECT answer_parts_to_copy.*, fields.id AS new_field_type_id
    FROM answer_parts_to_copy
    JOIN tmp_range_answer_options fields
    ON answer_parts_to_copy.field_type_type = 'RangeAnswerOption'
    AND fields.original_id = answer_parts_to_copy.field_type_id

    UNION

    SELECT answer_parts_to_copy.*, fields.id AS new_field_type_id
    FROM answer_parts_to_copy
    JOIN tmp_multi_answer_options fields
    ON answer_parts_to_copy.field_type_type = 'MultiAnswerOption'
    AND fields.original_id = answer_parts_to_copy.field_type_id

    UNION

    SELECT answer_parts_to_copy.*, fields.id AS new_field_type_id
    FROM answer_parts_to_copy
    JOIN tmp_matrix_answer_queries fields
    ON answer_parts_to_copy.field_type_type = 'MatrixAnswerQuery'
    AND fields.original_id = answer_parts_to_copy.field_type_id
  )
  INSERT INTO tmp_answer_parts (
    answer_text,
    answer_id,
    field_type_type,
    field_type_id,
    details_text,
    answer_text_in_english,
    original_language,
    sort_index,
    created_at,
    updated_at,
    original_id
  )
  SELECT
    answer_text,
    new_answer_id,
    field_type_type,
    answer_parts.new_field_type_id,
    details_text,
    answer_text_in_english,
    original_language,
    sort_index,
    new_created_at,
    new_updated_at,
    answer_parts.id
  FROM answer_parts_to_copy_with_resolved_field_types answer_parts;

  INSERT INTO tmp_answer_part_matrix_options (
    answer_part_id,
    matrix_answer_option_id,
    matrix_answer_drop_option_id,
    answer_text,
    created_at,
    updated_at
  )
  SELECT
    tmp_answer_parts.id,
    tmp_matrix_answer_options.id,
    tmp_matrix_answer_drop_options.id,
    answer_part_matrix_options.answer_text,
    tmp_answer_parts.created_at,
    tmp_answer_parts.updated_at
  FROM answer_part_matrix_options
  JOIN tmp_answer_parts
  ON tmp_answer_parts.original_id = answer_part_matrix_options.answer_part_id
  LEFT JOIN tmp_matrix_answer_options
  ON tmp_matrix_answer_options.original_id = answer_part_matrix_options.matrix_answer_option_id
  LEFT JOIN tmp_matrix_answer_drop_options
  ON tmp_matrix_answer_drop_options.original_id = answer_part_matrix_options.matrix_answer_drop_option_id;
END;
$$;

DROP FUNCTION IF EXISTS copy_answer_parts_end();
CREATE OR REPLACE FUNCTION copy_answer_parts_end()
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO answer_parts SELECT * FROM tmp_answer_parts;
  DROP TABLE tmp_answer_parts;
  INSERT INTO answer_part_matrix_options SELECT * FROM tmp_answer_part_matrix_options;
  DROP TABLE tmp_answer_part_matrix_options;
END;
$$;
