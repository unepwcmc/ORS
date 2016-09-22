DROP FUNCTION IF EXISTS copy_questionnaire_parts_start(
  old_questionnaire_id INTEGER, new_questionnaire_id INTEGER
);
CREATE OR REPLACE FUNCTION copy_questionnaire_parts_start(
  old_questionnaire_id INTEGER, new_questionnaire_id INTEGER
) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  -- use a temporary table to isolate the copied questionnaire_parts tree
  -- while resolving parent_id and part_id
  CREATE TEMP TABLE tmp_questionnaire_parts () INHERITS (questionnaire_parts);

  -- the truly amazing thing is: this table will use the same sequence
  -- to generate primary keys as the master table
  INSERT INTO tmp_questionnaire_parts (
    questionnaire_id,
    part_id,
    part_type,
    created_at,
    updated_at,
    parent_id,
    lft,
    rgt,
    original_id
  )
  SELECT
    CASE
      WHEN questionnaire_id IS NULL THEN NULL
      ELSE new_questionnaire_id
    END AS questionnaire_id,
    part_id,
    part_type,
    current_timestamp AS created_at,
    current_timestamp AS updated_at,
    parent_id,
    lft,
    rgt,
    parts.id AS original_id
  FROM questionnaire_parts_with_descendents(old_questionnaire_id) parts;

  -- udate parent_id
  UPDATE tmp_questionnaire_parts
  SET parent_id = parents.id
  FROM tmp_questionnaire_parts parents
  WHERE parents.original_id = tmp_questionnaire_parts.parent_id;
  -- NOTE: run the acts_as_nested_set rebuild script afterwards to reset lft & rgt

  PERFORM copy_answer_types_start(old_questionnaire_id);
  PERFORM copy_loop_sources_and_item_types_start(old_questionnaire_id, new_questionnaire_id);
  PERFORM copy_loop_items_start(old_questionnaire_id, new_questionnaire_id);
  PERFORM copy_sections_start(old_questionnaire_id);
  PERFORM copy_questions_start(old_questionnaire_id);
  PERFORM resolve_dependent_sections_start();
  PERFORM copy_extras_start(old_questionnaire_id, new_questionnaire_id);
  PERFORM copy_delegations_start(old_questionnaire_id, new_questionnaire_id);

  UPDATE tmp_questionnaire_parts
  SET part_id = tmp_sections.id
  FROM tmp_sections
  WHERE tmp_sections.original_id = tmp_questionnaire_parts.part_id
    AND tmp_questionnaire_parts.part_type = 'Section';

  UPDATE tmp_questionnaire_parts
  SET part_id = tmp_questions.id
  FROM tmp_questions
  WHERE tmp_questions.original_id = tmp_questionnaire_parts.part_id
    AND tmp_questionnaire_parts.part_type = 'Question';
  RETURN;

END;
$$;

DROP FUNCTION IF EXISTS copy_questionnaire_parts_end();
CREATE OR REPLACE FUNCTION copy_questionnaire_parts_end()
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM copy_loop_sources_and_item_types_end();
  PERFORM copy_answer_types_end();
  PERFORM copy_sections_end();
  PERFORM copy_questions_end();
  PERFORM resolve_dependent_sections_end();
  PERFORM copy_loop_items_end();
  PERFORM copy_extras_end();
  PERFORM copy_delegations_end();

  -- insert into questionnaire_parts
  INSERT INTO questionnaire_parts SELECT * FROM tmp_questionnaire_parts;
  DROP TABLE tmp_questionnaire_parts;
END;
$$;
