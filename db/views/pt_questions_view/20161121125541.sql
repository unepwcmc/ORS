CREATE OR REPLACE VIEW pt_questions_view AS
WITH RECURSIVE questionnaire_parts_with_descendents AS (
  SELECT
    id,
    questionnaire_id,
    part_id,
    part_type,
    parent_id,
    NULL::INT AS parent_part_id,
    NULL::TEXT AS parent_part_type,
    lft
  FROM questionnaire_parts
  WHERE questionnaire_parts.parent_id IS NULL

  UNION ALL

  SELECT
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
  questions.id,
  questionnaire_id,
  uidentifier,
  questions.answer_type_type,
  lft
FROM questionnaire_parts_with_descendents qp
JOIN questions ON questions.id = qp.part_id AND
  qp.part_type = 'Question';
