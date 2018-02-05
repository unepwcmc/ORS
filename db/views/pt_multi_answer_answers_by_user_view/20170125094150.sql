CREATE OR REPLACE VIEW pt_multi_answer_answers_by_user_view AS
SELECT
  q.id AS question_id,
  q.uidentifier,
  answers.id AS answer_id,
  answers.looping_identifier,
  CASE WHEN answers.id IS NOT NULL THEN mao.option_code ELSE 'EMPTY' END AS option_code,
  mao.details_field,
  ap.details_text,
  answers.user_id
FROM pt_questions_view q
LEFT JOIN answers ON answers.question_id = q.id
LEFT JOIN answer_parts ap ON ap.answer_id = answers.id AND
  ap.field_type_type::text = 'MultiAnswerOption'::text
LEFT JOIN pt_multi_answer_option_codes_view mao ON mao.multi_answer_option_id = ap.field_type_id 
AND q.id = mao.question_id
WHERE q.answer_type_type = 'MultiAnswer';
