-- DROP VIEW api_multi_answer_options_view;

CREATE OR REPLACE VIEW api_multi_answer_options_view AS
 WITH mao_lngs AS (
         SELECT maof_1.multi_answer_option_id,
            array_agg(upper(maof_1.language::text)) AS languages
           FROM multi_answer_option_fields maof_1
          WHERE squish_null(maof_1.option_text) IS NOT NULL
          GROUP BY maof_1.multi_answer_option_id
        )
 SELECT mao.id,
    mao.multi_answer_id,
    mao.sort_index,
    maof.option_text,
    upper(maof.language::text) AS language,
    maof.is_default_language,
    mao_lngs.languages
   FROM multi_answer_options mao
     JOIN multi_answer_option_fields maof ON maof.multi_answer_option_id = mao.id
     JOIN mao_lngs ON mao_lngs.multi_answer_option_id = mao.id
  WHERE squish_null(maof.option_text) IS NOT NULL;
