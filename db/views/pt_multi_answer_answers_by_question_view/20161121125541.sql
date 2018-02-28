CREATE OR REPLACE VIEW pt_multi_answer_answers_by_question_view AS
SELECT
  question_id,
  uidentifier,
  looping_identifier,
  option_code,
  region,
  COUNT(*)
FROM pt_multi_answer_answers_by_user_view
GROUP BY question_id, uidentifier, looping_identifier, region, option_code
ORDER BY question_id, looping_identifier;
