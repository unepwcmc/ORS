CREATE OR REPLACE VIEW pt_matrix_answer_option_codes_view AS 
SELECT
  questions.id AS question_id,
  questions.is_mandatory,
  ma.id AS matrix_answer_id,
  mao.id AS matrix_answer_drop_option_id,
  questions.uidentifier,
  maof.option_text,
  CASE
    WHEN "position"(maof.option_text, '='::text) > 0 THEN "substring"(squish_null(maof.option_text), 1, "position"(squish_null(maof.option_text), '='::text) - 1)
    ELSE 'UNKNOWN'::text
  END AS option_code
  FROM questions
  JOIN matrix_answers ma ON questions.answer_type_id = ma.id
  JOIN matrix_answer_drop_options mao ON ma.id = mao.matrix_answer_id
  JOIN matrix_answer_drop_option_fields maof ON mao.id = maof.matrix_answer_drop_option_id
    AND maof.is_default_language;
