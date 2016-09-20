DROP FUNCTION IF EXISTS copy_delegations(
  old_questionnaire_id INTEGER, new_questionnaire_id INTEGER
);
DROP FUNCTION IF EXISTS copy_delegations_start(
  old_questionnaire_id INTEGER, new_questionnaire_id INTEGER
);
CREATE OR REPLACE FUNCTION copy_delegations_start(
  old_questionnaire_id INTEGER, new_questionnaire_id INTEGER
) RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
  CREATE TEMP TABLE tmp_delegations () INHERITS (delegations);
  CREATE TEMP TABLE tmp_delegation_sections () INHERITS (delegation_sections);
  CREATE TEMP TABLE tmp_delegated_loop_item_names () INHERITS (delegated_loop_item_names);

  INSERT INTO tmp_delegations (
    questionnaire_id,
    user_delegate_id,
    remarks,
    from_submission,
    created_at,
    updated_at,
    original_id
  )
  SELECT
    new_questionnaire_id,
    user_delegate_id,
    remarks,
    from_submission,
    current_timestamp,
    current_timestamp,
    delegations.id
  FROM delegations
  WHERE questionnaire_id = old_questionnaire_id;

  INSERT INTO tmp_delegation_sections (
    delegation_id,
    section_id,
    created_at,
    updated_at,
    original_id
  )
  SELECT
    tmp_delegations.id,
    tmp_sections.id,
    tmp_delegations.created_at,
    tmp_delegations.updated_at,
    delegation_sections.id
  FROM delegation_sections
  JOIN tmp_delegations
  ON tmp_delegations.original_id = delegation_sections.delegation_id
  JOIN tmp_sections
  ON tmp_sections.original_id = delegation_sections.section_id;

  INSERT INTO tmp_delegated_loop_item_names (
    delegation_section_id,
    loop_item_name_id,
    created_at,
    updated_at
  )
  SELECT
    tmp_delegation_sections.id,
    tmp_loop_item_names.id,
    tmp_delegation_sections.created_at,
    tmp_delegation_sections.updated_at
  FROM delegated_loop_item_names
  JOIN tmp_delegation_sections
  ON tmp_delegation_sections.original_id = delegated_loop_item_names.delegation_section_id
  JOIN tmp_loop_item_names
  ON tmp_loop_item_names.original_id = delegated_loop_item_names.loop_item_name_id;
END;
$$;

DROP FUNCTION IF EXISTS copy_delegations_end();
CREATE OR REPLACE FUNCTION copy_delegations_end()
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO delegations
  SELECT * FROM tmp_delegations;
  DROP TABLE tmp_delegations;

  INSERT INTO delegation_sections
  SELECT * FROM tmp_delegation_sections;
  DROP TABLE tmp_delegation_sections;

  INSERT INTO delegated_loop_item_names
  SELECT * FROM tmp_delegated_loop_item_names;
  DROP TABLE tmp_delegated_loop_item_names;

  RETURN;
END;
$$;
