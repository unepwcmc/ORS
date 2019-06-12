-- DROP VIEW api_questions_tree_view;

CREATE OR REPLACE VIEW api_questions_tree_view AS
 WITH mao_options AS (
         SELECT mao.multi_answer_id,
            mao.language,
            array_agg(mao.option_text ORDER BY mao.sort_index) AS options
           FROM api_multi_answer_options_view mao
          GROUP BY mao.multi_answer_id, mao.language
        ), rao_options AS (
         SELECT rao.range_answer_id,
            rao.language,
            array_agg(rao.option_text ORDER BY rao.sort_index) AS options
           FROM api_range_answer_options_view rao
          GROUP BY rao.range_answer_id, rao.language
        ), mxao_options AS (
         SELECT mxao.matrix_answer_id,
            mxao.language,
            array_agg(mxao.title) AS options
           FROM api_matrix_answer_options_view mxao
           GROUP BY mxao.matrix_answer_id, mxao.language
        ), mado_options AS (
         SELECT mado.matrix_answer_id,
           mado.language,
           array_agg(mado.option_text) AS options
           FROM api_matrix_answer_drop_options_view mado
           GROUP BY mado.matrix_answer_id, mado.language
        )
 SELECT q.id,
    q.section_id,
    q.answer_type_id,
    q.answer_type_type,
    q.is_mandatory,
    q.language,
    q.is_default_language,
    q.title,
    q.short_title,
    q.description,
    q.lft,
    q.languages,
    s.questionnaire_id,
    s.section_type,
    s.loop_source_id,
    s.loop_item_type_id,
    s.looping_section_id,
    s.depends_on_question_id,
    s.depends_on_option_id,
    s.depends_on_option_value,
    s.is_hidden,
    s.display_in_tab,
    s.title AS section_title,
    s.tab_title AS section_tab_title,
    s.language AS section_language,
    s.is_default_language AS section_is_default_language,
    s.path,
    COALESCE(mao_options.options, rao_options.options::text[], mado_options.options::text[], mxao_options.options::text[]) AS options
   FROM api_questions_view q
     JOIN api_sections_tree_view s ON q.section_id = s.id AND (q.language = s.language OR s.is_default_language AND NOT s.languages @> ARRAY[q.language])
     LEFT JOIN mao_options ON mao_options.multi_answer_id = q.answer_type_id AND q.answer_type_type = 'MultiAnswer' AND mao_options.language = q.language
     LEFT JOIN rao_options ON rao_options.range_answer_id = q.answer_type_id AND q.answer_type_type = 'RangeAnswer' AND rao_options.language = q.language
     LEFT JOIN mxao_options ON mxao_options.matrix_answer_id = q.answer_type_id AND q.answer_type_type = 'MatrixAnswer' AND mxao_options.language = q.language
     LEFT JOIN mado_options ON mado_options.matrix_answer_id = q.answer_type_id AND q.answer_type_type = 'MatrixAnswer' AND mado_options.language = q.language
