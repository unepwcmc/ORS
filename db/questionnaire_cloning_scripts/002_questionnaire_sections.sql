DROP FUNCTION IF EXISTS questionnaire_sections(
  in_questionnaire_id INTEGER
);
CREATE OR REPLACE FUNCTION questionnaire_sections(
  in_questionnaire_id INTEGER
) RETURNS SETOF sections
LANGUAGE sql AS $$

  WITH section_parts AS (
    SELECT * FROM questionnaire_parts_with_descendents(in_questionnaire_id)
    WHERE part_type = 'Section'
  )
  SELECT sections.*
  FROM section_parts
  JOIN sections ON sections.id = part_id
$$;
