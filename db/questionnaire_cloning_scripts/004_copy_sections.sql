DROP FUNCTION IF EXISTS copy_sections_start(
  in_questionnaire_id INTEGER
);
CREATE OR REPLACE FUNCTION copy_sections_start(
  in_questionnaire_id INTEGER
) RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
  CREATE TEMP TABLE tmp_sections () INHERITS (sections);
  CREATE TEMP TABLE tmp_section_fields () INHERITS (section_fields);

  WITH sections_to_copy AS (
    SELECT * FROM questionnaire_sections(in_questionnaire_id)
  ), sections_to_copy_with_resolved_answer_types AS (
    SELECT sections_to_copy.*, NULL AS new_answer_type_id
    FROM sections_to_copy
    WHERE answer_type_id IS NULL

    UNION

    SELECT sections_to_copy.*, tmp.id AS new_answer_type_id
    FROM sections_to_copy
    JOIN tmp_text_answers tmp
    ON sections_to_copy.answer_type_type = 'TextAnswer'
    AND tmp.original_id = sections_to_copy.answer_type_id

    UNION

    SELECT sections_to_copy.*, tmp.id AS new_answer_type_id
    FROM sections_to_copy
    JOIN tmp_numeric_answers tmp
    ON sections_to_copy.answer_type_type = 'NumericAnswer'
    AND tmp.original_id = sections_to_copy.answer_type_id

    UNION

    SELECT sections_to_copy.*, tmp.id AS new_answer_type_id
    FROM sections_to_copy
    JOIN tmp_rank_answers tmp
    ON sections_to_copy.answer_type_type = 'RankAnswer'
    AND tmp.original_id = sections_to_copy.answer_type_id

    UNION

    SELECT sections_to_copy.*, tmp.id AS new_answer_type_id
    FROM sections_to_copy
    JOIN tmp_range_answers tmp
    ON sections_to_copy.answer_type_type = 'RangeAnswer'
    AND tmp.original_id = sections_to_copy.answer_type_id

    UNION

    SELECT sections_to_copy.*, tmp.id AS new_answer_type_id
    FROM sections_to_copy
    JOIN tmp_multi_answers tmp
    ON sections_to_copy.answer_type_type = 'MultiAnswer'
    AND tmp.original_id = sections_to_copy.answer_type_id

    UNION

    SELECT sections_to_copy.*, tmp.id AS new_answer_type_id
    FROM sections_to_copy
    JOIN tmp_matrix_answers tmp
    ON sections_to_copy.answer_type_type = 'MatrixAnswer'
    AND tmp.original_id = sections_to_copy.answer_type_id
  ), sections_to_copy_with_resolved_loop_source_and_item_type AS (
    SELECT sections_to_copy.*,
    tmp_loop_sources.id AS new_loop_source_id,
    tmp_loop_item_types.id AS new_loop_item_type_id
    FROM sections_to_copy_with_resolved_answer_types sections_to_copy
    LEFT JOIN tmp_loop_item_types
    ON tmp_loop_item_types.original_id = sections_to_copy.loop_item_type_id
    LEFT JOIN tmp_loop_sources
    ON tmp_loop_sources.original_id = sections_to_copy.loop_source_id
  )
  INSERT INTO tmp_sections (
    section_type,
    answer_type_id,
    answer_type_type,
    loop_source_id,
    loop_item_type_id,
    depends_on_option_id,
    depends_on_option_value,
    depends_on_question_id,
    is_hidden,
    starts_collapsed,
    display_in_tab,
    created_at,
    updated_at,
    last_edited,
    original_id
  )
  SELECT
    section_type,
    new_answer_type_id,
    answer_type_type,
    new_loop_source_id,
    new_loop_item_type_id,
    depends_on_option_id,
    depends_on_option_value,
    depends_on_question_id,
    is_hidden,
    starts_collapsed,
    display_in_tab,
    current_timestamp,
    current_timestamp,
    NULL,
    id
  FROM sections_to_copy_with_resolved_loop_source_and_item_type;

  -- copy section fields
  INSERT INTO tmp_section_fields (
    title,
    language,
    description,
    section_id,
    created_at,
    updated_at,
    is_default_language,
    tab_title
  )
  SELECT
    title,
    language,
    description,
    tmp_sections.id,
    current_timestamp,
    current_timestamp,
    is_default_language,
    tab_title
  FROM section_fields t
  JOIN tmp_sections
  ON tmp_sections.original_id = t.section_id;
END;
$$;

DROP FUNCTION IF EXISTS copy_sections_end();
CREATE OR REPLACE FUNCTION copy_sections_end()
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO sections SELECT * FROM tmp_sections;
  DROP TABLE tmp_sections;
  INSERT INTO section_fields SELECT * FROM tmp_section_fields;
  DROP TABLE tmp_section_fields;
END;
$$;
