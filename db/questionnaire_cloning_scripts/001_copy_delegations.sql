DROP FUNCTION IF EXISTS copy_delegations(
  old_questionnaire_id INTEGER, new_questionnaire_id INTEGER
);
CREATE OR REPLACE FUNCTION copy_delegations(
  old_questionnaire_id INTEGER, new_questionnaire_id INTEGER
) RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
  WITH copied_delegations AS (
    INSERT INTO delegations (
      questionnaire_id,
      user_delegate_id,
      remarks,
      from_submission,
      created_at,
      updated_at,
      original_id
    )
    SELECT
      questionnaires.id,
      user_delegate_id,
      remarks,
      from_submission,
      questionnaires.created_at,
      questionnaires.updated_at,
      delegations.id
    FROM delegations
    JOIN questionnaires
    ON questionnaires.original_id = delegations.questionnaire_id
    WHERE questionnaires.id = new_questionnaire_id
    RETURNING *
  ), copied_delegation_sections AS (
    INSERT INTO delegation_sections (
      delegation_id,
      section_id,
      created_at,
      updated_at,
      original_id
    )
    SELECT
      copied_delegations.id,
      tmp_sections.id,
      copied_delegations.created_at,
      copied_delegations.updated_at,
      delegation_sections.id
    FROM delegation_sections
    JOIN copied_delegations
    ON copied_delegations.original_id = delegation_sections.delegation_id
    JOIN tmp_sections
    ON tmp_sections.original_id = delegation_sections.section_id
    RETURNING *
  )
  INSERT INTO delegated_loop_item_names (
    delegation_section_id,
    loop_item_name_id,
    created_at,
    updated_at
  )
  SELECT
    copied_delegation_sections.id,
    tmp_loop_item_names.id,
    copied_delegation_sections.created_at,
    copied_delegation_sections.updated_at
  FROM delegated_loop_item_names
  JOIN copied_delegation_sections
  ON copied_delegation_sections.original_id = delegated_loop_item_names.delegation_section_id
  JOIN tmp_loop_item_names
  ON tmp_loop_item_names.original_id = delegated_loop_item_names.loop_item_name_id;
END;
$$;
