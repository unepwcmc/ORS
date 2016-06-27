DROP VIEW IF EXISTS api_answers_view;

CREATE OR REPLACE VIEW api_answers_view AS
 SELECT answers.id,
    answers.question_id,
    answers.user_id,
    (users.first_name::text || ' '::text) || users.last_name::text AS respondent,
    answers.looping_identifier,
    answers.question_answered,
    ap.answer_text,
    ap.field_type_type,
    ap.field_type_id,
    ap.details_text,
    ap.answer_text_in_english
   FROM answers
     JOIN answer_parts ap ON ap.answer_id = answers.id
     JOIN users ON users.id = answers.user_id;
