CREATE OR REPLACE VIEW pt_matrix_answer_answers_by_user_view AS
SELECT
  q.id AS question_id,
  q.uidentifier,
  answers.id AS answer_id,
  ap.field_type_id AS matrix_answer_query_id,
  answers.looping_identifier,
  CASE WHEN answers.id IS NOT NULL THEN mao.option_code ELSE 'EMPTY' END AS option_code,
  answers.user_id
FROM pt_questions_view q
LEFT JOIN answers ON answers.question_id = q.id
LEFT JOIN answer_parts ap ON ap.answer_id = answers.id AND
  ap.field_type_type::text = 'MatrixAnswerQuery'::text
LEFT JOIN answer_part_matrix_options apm ON apm.answer_part_id = ap.id
LEFT JOIN pt_matrix_answer_option_codes_view mao ON mao.matrix_answer_drop_option_id = apm.matrix_answer_drop_option_id
AND q.id = mao.question_id
WHERE q.answer_type_type = 'MatrixAnswer';