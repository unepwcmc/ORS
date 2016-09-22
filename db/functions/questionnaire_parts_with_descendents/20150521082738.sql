DROP FUNCTION IF EXISTS questionnaire_parts_with_descendents(in_questionnaire_id INT);
CREATE FUNCTION questionnaire_parts_with_descendents(in_questionnaire_id INT)
RETURNS SETOF questionnaire_parts AS $$
  WITH RECURSIVE questionnaire_parts_with_descendents AS (
    SELECT questionnaire_parts.* FROM questionnaire_parts
    WHERE questionnaire_parts.questionnaire_id = in_questionnaire_id
    UNION
    SELECT hi.* FROM questionnaire_parts hi
    JOIN questionnaire_parts_with_descendents h ON h.id = hi.parent_id
  )
  SELECT * FROM questionnaire_parts_with_descendents;
$$ LANGUAGE SQL;
