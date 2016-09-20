DROP VIEW IF EXISTS api_answers_view;

CREATE OR REPLACE VIEW api_answers_view AS
 SELECT answers.id,
    answers.question_id,
    answers.user_id,
    (users.first_name::text || ' '::text) || users.last_name::text AS respondent,
    answers.looping_identifier,
    answers.question_answered,
    ap.field_type_type,
    ap.field_type_id,
        CASE
            WHEN ap.field_type_type::text = 'MultiAnswerOption'::text THEN mao.option_text
            WHEN ap.field_type_type::text = 'RangeAnswerOption'::text THEN rao.option_text::text
            ELSE ap.answer_text
        END AS answer_text,
        CASE
            WHEN ap.field_type_type::text = 'MultiAnswerOption'::text THEN mao.language
            WHEN ap.field_type_type::text = 'RangeAnswerOption'::text THEN rao.language
            ELSE ''
        END AS language,
    ap.details_text,
    ap.answer_text_in_english
   FROM answers
     JOIN answer_parts ap ON ap.answer_id = answers.id
     JOIN users ON users.id = answers.user_id
     LEFT JOIN api_multi_answer_options_view mao ON mao.id = ap.field_type_id AND ap.field_type_type::text = 'MultiAnswerOption'::text
     LEFT JOIN api_range_answer_options_view rao ON rao.id = ap.field_type_id AND ap.field_type_type::text = 'RangeAnswerOption'::text;
