CREATE OR REPLACE VIEW pt_multi_answer_answers_by_user_view AS
SELECT
  authorized_submitters.questionnaire_id,
  q.id AS question_id,
  q.uidentifier,
  answers.id AS answer_id,
  answers.looping_identifier,
  users.id AS user_id,
  CASE
    WHEN users.region IN ('Asia', 'Oceania') THEN 'Asia/Oceania'
    WHEN users.region IN ('North America', 'Latin America and the Caribbean') THEN 'North/Latin'
    ELSE users.region
  END AS region,
  CASE WHEN answers.id IS NOT NULL THEN mao.option_code ELSE 'EMPTY' END AS option_code
FROM authorized_submitters
JOIN users ON users.id = authorized_submitters.user_id
LEFT JOIN pt_questions_view q ON q.questionnaire_id = authorized_submitters.questionnaire_id AND
  q.answer_type_type = 'MultiAnswer'
LEFT JOIN answers ON answers.user_id = users.id AND
  answers.question_id = q.id
LEFT JOIN answer_parts ap ON ap.answer_id = answers.id AND
  ap.field_type_type::text = 'MultiAnswerOption'::text
LEFT JOIN pt_multi_answer_option_codes_view mao ON mao.multi_answer_option_id = ap.field_type_id 
AND q.id = mao.question_id;
