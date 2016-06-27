-- DROP VIEW api_questions_looping_contexts_view;

CREATE OR REPLACE VIEW api_questions_looping_contexts_view AS
 SELECT questions.id AS question_id,
    slc.section_id,
    slc.looping_identifier,
    slc.looping_context,
    slc.li_lft,
    slc.language
   FROM api_sections_looping_contexts_view slc
     JOIN questions ON slc.section_id = questions.section_id;
