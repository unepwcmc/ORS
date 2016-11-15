DROP FUNCTION IF EXISTS copy_questions_start(
  old_questionnaire_id INTEGER
);
CREATE OR REPLACE FUNCTION copy_questions_start(
  old_questionnaire_id INTEGER
) RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN

  CREATE TEMP TABLE tmp_questions () INHERITS (questions);
  CREATE TEMP TABLE tmp_question_fields () INHERITS (question_fields);
  CREATE TEMP TABLE tmp_question_loop_types () INHERITS (question_loop_types);

  WITH questions_to_copy AS (
    SELECT * FROM questionnaire_questions(old_questionnaire_id)
  ), questions_to_copy_with_resolved_answer_types AS (
    SELECT questions_to_copy.*, tmp.id AS new_answer_type_id
    FROM questions_to_copy
    JOIN tmp_text_answers tmp
    ON questions_to_copy.answer_type_type = 'TextAnswer'
    AND tmp.original_id = questions_to_copy.answer_type_id

    UNION

    SELECT questions_to_copy.*, tmp.id AS new_answer_type_id
    FROM questions_to_copy
    JOIN tmp_numeric_answers tmp
    ON questions_to_copy.answer_type_type = 'NumericAnswer'
    AND tmp.original_id = questions_to_copy.answer_type_id

    UNION

    SELECT questions_to_copy.*, tmp.id AS new_answer_type_id
    FROM questions_to_copy
    JOIN tmp_rank_answers tmp
    ON questions_to_copy.answer_type_type = 'RankAnswer'
    AND tmp.original_id = questions_to_copy.answer_type_id

    UNION

    SELECT questions_to_copy.*, tmp.id AS new_answer_type_id
    FROM questions_to_copy
    JOIN tmp_range_answers tmp
    ON questions_to_copy.answer_type_type = 'RangeAnswer'
    AND tmp.original_id = questions_to_copy.answer_type_id

    UNION

    SELECT questions_to_copy.*, tmp.id AS new_answer_type_id
    FROM questions_to_copy
    JOIN tmp_multi_answers tmp
    ON questions_to_copy.answer_type_type = 'MultiAnswer'
    AND tmp.original_id = questions_to_copy.answer_type_id

    UNION

    SELECT questions_to_copy.*, tmp.id AS new_answer_type_id
    FROM questions_to_copy
    JOIN tmp_matrix_answers tmp
    ON questions_to_copy.answer_type_type = 'MatrixAnswer'
    AND tmp.original_id = questions_to_copy.answer_type_id
  )
  INSERT INTO tmp_questions (
    uidentifier,
    section_id,
    answer_type_id,
    answer_type_type,
    is_mandatory,
    created_at,
    updated_at,
    last_edited,
    original_id
  )
  SELECT
    uidentifier,
    tmp_sections.id,
    new_answer_type_id,
    t.answer_type_type,
    is_mandatory,
    current_timestamp,
    current_timestamp,
    NULL,
    t.id
  FROM questions_to_copy_with_resolved_answer_types t
  JOIN tmp_sections
  ON tmp_sections.original_id = t.section_id;

  INSERT INTO tmp_question_fields (
    title,
    short_title,
    language,
    description,
    question_id,
    created_at,
    updated_at,
    is_default_language
  )
  SELECT
    title,
    short_title,
    language,
    description,
    tmp_questions.id,
    current_timestamp,
    current_timestamp,
    is_default_language
  FROM question_fields t
  JOIN tmp_questions
  ON tmp_questions.original_id = t.question_id;

  INSERT INTO tmp_question_loop_types (
    question_id,
    loop_item_type_id,
    created_at,
    updated_at
  )
  SELECT
    tmp_questions.id,
    tmp_loop_item_types.id,
    tmp_questions.created_at,
    tmp_questions.updated_at
  FROM question_loop_types
  JOIN tmp_questions
  ON tmp_questions.original_id = question_loop_types.question_id
  JOIN tmp_loop_item_types
  ON tmp_loop_item_types.original_id = question_loop_types.loop_item_type_id;

END;
$$;

DROP FUNCTION IF EXISTS resolve_dependent_question_in_copied_sections();
DROP FUNCTION IF EXISTS resolve_dependent_sections_start();
CREATE OR REPLACE FUNCTION resolve_dependent_sections_start()
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
  CREATE TEMP TABLE tmp_dependent_sections AS
  SELECT tmp_sections.id AS id,
  tmp_questions.id AS depends_on_question_id,
  copied_multi_answer_options.id AS depends_on_option_id
  FROM tmp_sections
  JOIN tmp_questions
  ON tmp_questions.original_id = tmp_sections.depends_on_question_id
  JOIN (
    SELECT multi_answer_options.* FROM multi_answer_options
    JOIN tmp_multi_answers
    ON multi_answer_options.multi_answer_id = tmp_multi_answers.id
  ) copied_multi_answer_options
  ON copied_multi_answer_options.original_id = tmp_sections.depends_on_option_id;
  CREATE UNIQUE INDEX ON tmp_dependent_sections (id);
END;
$$;

DROP FUNCTION IF EXISTS resolve_dependent_sections_end();
CREATE OR REPLACE FUNCTION resolve_dependent_sections_end()
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
  UPDATE sections
  SET depends_on_question_id = tmp_dependent_sections.depends_on_question_id,
  depends_on_option_id = tmp_dependent_sections.depends_on_option_id
  FROM tmp_dependent_sections
  WHERE tmp_dependent_sections.id = sections.id;
  DROP TABLE tmp_dependent_sections;
END;
$$;

DROP FUNCTION IF EXISTS copy_questions_end();
CREATE OR REPLACE FUNCTION copy_questions_end()
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO questions SELECT * FROM tmp_questions;
  DROP TABLE tmp_questions;
  INSERT INTO question_fields SELECT * FROM tmp_question_fields;
  DROP TABLE tmp_question_fields;
  INSERT INTO question_loop_types SELECT * FROM tmp_question_loop_types;
  DROP TABLE tmp_question_loop_types;
END;
$$;
