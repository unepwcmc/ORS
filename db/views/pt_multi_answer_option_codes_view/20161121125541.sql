CREATE OR REPLACE VIEW pt_multi_answer_option_codes_view AS
SELECT
  questions.id AS question_id,
  questions.is_mandatory,ma.id AS multi_answer_id,
  mao.id As multi_answer_option_id,
  uidentifier,
  maof.option_text,
  SUBSTRING(
    COALESCE(SQUISH_NULL(maof.option_text), 'UNKNOWN') FROM 1 FOR 1
  ) AS option_code
FROM questions
JOIN multi_answers ma ON questions.answer_type_id = ma.id
JOIN multi_answer_options mao ON ma.id = mao.multi_answer_id
JOIN multi_answer_option_fields maof ON mao.id = maof.multi_answer_option_id AND
  maof.is_default_language;
