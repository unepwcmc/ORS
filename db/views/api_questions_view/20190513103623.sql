-- DROP VIEW api_questions_view;

CREATE OR REPLACE VIEW api_questions_view AS
 WITH q_lngs AS (
         SELECT question_fields_1.question_id,
            array_agg(upper(question_fields_1.language::text)) AS languages
           FROM question_fields question_fields_1
          WHERE squish_null(question_fields_1.title) IS NOT NULL
          GROUP BY question_fields_1.question_id
        )
 SELECT questions.id,
    questions.section_id,
    questions.answer_type_id,
    questions.answer_type_type,
    questions.is_mandatory,
    upper(question_fields.language::text) AS language,
    question_fields.is_default_language,
    strip_tags(question_fields.title) AS title,
    strip_tags(question_fields.short_title::text) AS short_title,
    strip_tags(question_fields.description) AS description,
    qp.lft,
    q_lngs.languages
   FROM questions
     JOIN question_fields ON questions.id = question_fields.question_id
     JOIN questionnaire_parts qp ON qp.part_type::text = 'Question'::text AND qp.part_id = questions.id
     JOIN q_lngs ON q_lngs.question_id = questions.id
  WHERE (questions.answer_type_type::text = ANY (ARRAY['MultiAnswer'::character varying::text, 'RangeAnswer'::character varying::text, 'NumericAnswer'::character varying::text, 'MatrixAnswer'::character varying::text])) AND squish_null(question_fields.title) IS NOT NULL;
