DROP TYPE IF EXISTS answer_type CASCADE;
CREATE TYPE answer_type AS (answer_type_id INT, answer_type_type TEXT);

DROP FUNCTION IF EXISTS questionnaire_answer_types(in_questionnaire_id INT, in_answer_type TEXT);
CREATE FUNCTION questionnaire_answer_types(in_questionnaire_id INT, in_answer_type TEXT)
RETURNS SETOF answer_type AS $$
  WITH questionnaire_parts_to_copy AS (
    SELECT * FROM questionnaire_parts_with_descendents(in_questionnaire_id)
  )
  SELECT answer_type_id, in_answer_type FROM (
    SELECT answer_type_id
    FROM sections
    JOIN questionnaire_parts_to_copy t
    ON t.part_type = 'Section' AND t.part_id = sections.id
    WHERE sections.answer_type_type = in_answer_type
    UNION
    SELECT answer_type_id
    FROM questions
    JOIN questionnaire_parts_to_copy t
    ON t.part_type = 'Question' AND t.part_id = questions.id
    WHERE questions.answer_type_type = in_answer_type
  ) t
  GROUP BY answer_type_id
$$ LANGUAGE SQL;
