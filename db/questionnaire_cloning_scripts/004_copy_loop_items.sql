DROP FUNCTION IF EXISTS copy_loop_items_start(
  old_questionnaire_id INTEGER, new_questionnaire_id INTEGER
);
CREATE OR REPLACE FUNCTION copy_loop_items_start(
  old_questionnaire_id INTEGER, new_questionnaire_id INTEGER
) RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
  CREATE TEMP TABLE tmp_loop_item_names () INHERITS (loop_item_names);
  CREATE TEMP TABLE tmp_loop_item_name_fields () INHERITS (loop_item_name_fields);
  CREATE TEMP TABLE tmp_loop_items () INHERITS (loop_items);

  INSERT INTO tmp_loop_item_names (
    loop_source_id,
    loop_item_type_id,
    created_at,
    updated_at,
    original_id
  )
  SELECT
    tmp_loop_sources.id,
    tmp_loop_item_types.id,
    current_timestamp,
    current_timestamp,
    loop_item_names.id
  FROM loop_item_names
  JOIN tmp_loop_sources
  ON tmp_loop_sources.original_id = loop_item_names.loop_source_id
  JOIN tmp_loop_item_types
  ON tmp_loop_item_types.original_id = loop_item_names.loop_item_type_id;

  INSERT INTO tmp_loop_item_name_fields (
    loop_item_name_id,
    item_name,
    language,
    is_default_language,
    created_at,
    updated_at
  )
  SELECT
    tmp_loop_item_names.id,
    item_name,
    language,
    is_default_language,
    tmp_loop_item_names.created_at,
    tmp_loop_item_names.updated_at
  FROM loop_item_name_fields
  JOIN tmp_loop_item_names
  ON tmp_loop_item_names.original_id = loop_item_name_fields.loop_item_name_id;

  INSERT INTO tmp_loop_items (
    loop_item_type_id,
    loop_item_name_id,
    parent_id,
    lft,
    rgt,
    sort_index,
    created_at,
    updated_at,
    original_id
  )
  SELECT
    tmp_loop_item_types.id,
    tmp_loop_item_names.id,
    loop_items.parent_id,
    loop_items.lft,
    loop_items.rgt,
    sort_index,
    current_timestamp,
    current_timestamp,
    loop_items.id
  FROM loop_items
  JOIN tmp_loop_item_types
  ON tmp_loop_item_types.original_id = loop_items.loop_item_type_id
  JOIN tmp_loop_item_names
  ON tmp_loop_item_names.original_id = loop_items.loop_item_name_id;

  -- udate parent_id
  UPDATE tmp_loop_items
  SET parent_id = parents.id
  FROM tmp_loop_items parents
  WHERE parents.original_id = tmp_loop_items.parent_id;
  -- NOTE: run the acts_as_nested_set rebuild script afterwards to reset lft & rgt
END;
$$;

DROP FUNCTION IF EXISTS copy_loop_items_end();
CREATE OR REPLACE FUNCTION copy_loop_items_end()
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO loop_item_names
  SELECT * FROM tmp_loop_item_names;
  DROP TABLE tmp_loop_item_names;

  INSERT INTO loop_item_name_fields
  SELECT * FROM tmp_loop_item_name_fields;
  DROP TABLE tmp_loop_item_name_fields;

  INSERT INTO loop_items SELECT * FROM tmp_loop_items;
  DROP TABLE tmp_loop_items;
END;
$$;
