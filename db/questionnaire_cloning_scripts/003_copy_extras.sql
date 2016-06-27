DROP FUNCTION IF EXISTS copy_extras(
  old_questionnaire_id INTEGER, new_questionnaire_id INTEGER
);
CREATE OR REPLACE FUNCTION copy_extras(
  old_questionnaire_id INTEGER, new_questionnaire_id INTEGER
) RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
  CREATE TEMP TABLE tmp_extras () INHERITS (extras);

  INSERT INTO tmp_extras (
    name,
    loop_item_type_id,
    field_type,
    created_at,
    updated_at,
    original_id
  )
  SELECT
    extras.name,
    tmp_loop_item_types.id,
    field_type,
    current_timestamp,
    current_timestamp,
    extras.id
  FROM extras
  JOIN tmp_loop_item_types
  ON tmp_loop_item_types.original_id = extras.loop_item_type_id;

  WITH copied_item_extras AS (
    INSERT INTO item_extras (
      loop_item_name_id,
      extra_id,
      created_at,
      updated_at,
      original_id
    )
    SELECT
      tmp_loop_item_names.id,
      tmp_extras.id,
      current_timestamp,
      current_timestamp,
      item_extras.id
    FROM item_extras
    JOIN tmp_extras
    ON tmp_extras.original_id = item_extras.extra_id
    JOIN tmp_loop_item_names
    ON tmp_loop_item_names.original_id = item_extras.loop_item_name_id
    RETURNING *
  )
  INSERT INTO item_extra_fields (
    item_extra_id,
    language,
    value,
    is_default_language,
    created_at,
    updated_at
  )
  SELECT
    copied_item_extras.id,
    language,
    value,
    is_default_language,
    current_timestamp,
    current_timestamp
  FROM item_extra_fields
  JOIN copied_item_extras
  ON copied_item_extras.original_id = item_extra_fields.item_extra_id;

  INSERT INTO section_extras (
    section_id,
    extra_id,
    created_at,
    updated_at
  )
  SELECT
    tmp_sections.id,
    tmp_extras.id,
    tmp_sections.created_at,
    tmp_sections.updated_at
  FROM section_extras
  JOIN tmp_sections
  ON tmp_sections.original_id = section_extras.section_id
  JOIN tmp_extras
  ON tmp_extras.original_id = section_extras.extra_id;

  INSERT INTO question_extras (
    question_id,
    extra_id,
    created_at,
    updated_at
  )
  SELECT
    tmp_questions.id,
    tmp_extras.id,
    tmp_questions.created_at,
    tmp_questions.updated_at
  FROM section_extras
  JOIN tmp_questions
  ON tmp_questions.original_id = section_extras.section_id
  JOIN tmp_extras
  ON tmp_extras.original_id = section_extras.extra_id;

  INSERT INTO extras SELECT * FROM tmp_extras;
  DROP TABLE tmp_extras;
END;
$$;
