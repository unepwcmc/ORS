DROP FUNCTION IF EXISTS questionnaire_questions(
  in_questionnaire_id INTEGER
);
CREATE OR REPLACE FUNCTION questionnaire_questions(
  in_questionnaire_id INTEGER
) RETURNS SETOF questions
LANGUAGE sql AS $$

  WITH question_parts AS (
    SELECT * FROM questionnaire_parts_with_descendents(in_questionnaire_id)
    WHERE part_type = 'Question'
  )
  SELECT questions.*
  FROM question_parts
  JOIN questions ON questions.id = part_id
$$;
