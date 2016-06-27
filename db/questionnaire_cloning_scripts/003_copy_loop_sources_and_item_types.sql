DROP FUNCTION IF EXISTS copy_loop_sources_and_item_types_start(
  old_questionnaire_id INTEGER, new_questionnaire_id INTEGER
);
CREATE OR REPLACE FUNCTION copy_loop_sources_and_item_types_start(
  old_questionnaire_id INTEGER, new_questionnaire_id INTEGER
) RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
  -- create temp tables to hold loop sources and answer types for the duration of the cloning
  CREATE TEMP TABLE tmp_loop_sources () INHERITS (loop_sources);
  CREATE TEMP TABLE tmp_loop_item_types () INHERITS (loop_item_types);

  INSERT INTO tmp_loop_sources(
    name,
    questionnaire_id,
    created_at,
    updated_at,
    original_id
  )
  SELECT
    name,
    new_questionnaire_id,
    current_timestamp,
    current_timestamp,
    loop_sources.id
  FROM loop_sources
  WHERE questionnaire_id = old_questionnaire_id;

  INSERT INTO source_files (
    loop_source_id,
    source_file_name,
    source_content_type,
    source_file_size,
    parse_status,
    source_updated_at,
    created_at,
    updated_at
  )
  SELECT
    tmp_loop_sources.id,
    source_file_name,
    source_content_type,
    source_file_size,
    parse_status,
    tmp_loop_sources.updated_at,
    tmp_loop_sources.created_at,
    tmp_loop_sources.updated_at
  FROM source_files
  JOIN tmp_loop_sources
  ON tmp_loop_sources.original_id = source_files.loop_source_id;

  WITH copied_filtering_fields AS (
    INSERT INTO filtering_fields (
      name,
      questionnaire_id,
      created_at,
      updated_at,
      original_id
    )
    SELECT
      name,
      new_questionnaire_id,
      current_timestamp,
      current_timestamp,
      filtering_fields.id
    FROM filtering_fields
    WHERE questionnaire_id = old_questionnaire_id
    RETURNING *
  )
  INSERT INTO tmp_loop_item_types (
    loop_source_id,
    filtering_field_id,
    name,
    parent_id,
    lft,
    rgt,
    created_at,
    updated_at,
    original_id
  )
  SELECT
    tmp_loop_sources.id,
    copied_filtering_fields.id,
    loop_item_types.name,
    parent_id,
    lft,
    rgt,
    current_timestamp,
    current_timestamp,
    loop_item_types.id
  FROM loop_item_types
  LEFT JOIN tmp_loop_sources
  ON tmp_loop_sources.original_id = loop_item_types.loop_source_id
  LEFT JOIN copied_filtering_fields
  ON copied_filtering_fields.original_id = loop_item_types.filtering_field_id;

  -- udate parent_id
  UPDATE tmp_loop_item_types
  SET parent_id = parents.id
  FROM tmp_loop_item_types parents
  WHERE parents.original_id = tmp_loop_item_types.parent_id;
  -- NOTE: run the acts_as_nested_set rebuild script afterwards to reset lft & rgt
  RETURN;
END;
$$;

DROP FUNCTION IF EXISTS copy_loop_sources_and_item_types_end();
CREATE OR REPLACE FUNCTION copy_loop_sources_and_item_types_end()
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO loop_item_types
  SELECT * FROM tmp_loop_item_types;
  DROP TABLE tmp_loop_item_types;

  INSERT INTO loop_sources
  SELECT * FROM tmp_loop_sources;
  DROP TABLE tmp_loop_sources;
  RETURN;
END;
$$;
