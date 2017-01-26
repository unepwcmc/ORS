CREATE OR REPLACE VIEW pt_questions_view AS
WITH RECURSIVE questionnaire_parts_with_descendents AS (
  SELECT
    section_fields.tab_title AS root_section,
    questionnaire_parts.id,
    questionnaire_parts.questionnaire_id,
    questionnaire_parts.part_id,
    questionnaire_parts.part_type,
    questionnaire_parts.parent_id,
    NULL::integer AS parent_part_id,
    NULL::text AS parent_part_type,
    questionnaire_parts.lft
  FROM questionnaire_parts
  LEFT JOIN sections ON sections.id = part_id AND part_type = 'Section'
  LEFT JOIN section_fields ON section_fields.section_id = sections.id AND section_fields.is_default_language
  WHERE questionnaire_parts.parent_id IS NULL

  UNION ALL

  SELECT
    h.root_section,
    hi.id,
    h.questionnaire_id,
    hi.part_id,
    hi.part_type,
    hi.parent_id,
    h.part_id,
    h.part_type,
    hi.lft
  FROM questionnaire_parts hi
  JOIN questionnaire_parts_with_descendents h ON h.id = hi.parent_id
)
SELECT
  qp.root_section,
  questions.id,
  qp.questionnaire_id,
  questions.uidentifier,
  questions.answer_type_type,
  qp.lft
FROM questionnaire_parts_with_descendents qp
JOIN questions ON questions.id = qp.part_id AND qp.part_type::text = 'Question'::text;
