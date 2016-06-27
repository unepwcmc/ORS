-- DROP VIEW api_range_answer_options_view;

CREATE OR REPLACE VIEW api_range_answer_options_view AS
 WITH rao_lngs AS (
         SELECT raof_1.range_answer_option_id,
            array_agg(upper(raof_1.language::text)) AS languages
           FROM range_answer_option_fields raof_1
          WHERE squish_null(raof_1.option_text::text) IS NOT NULL
          GROUP BY raof_1.range_answer_option_id
        )
 SELECT rao.id,
    rao.range_answer_id,
    rao.sort_index,
    raof.option_text,
    upper(raof.language::text) AS language,
    raof.is_default_language,
    rao_lngs.languages
   FROM range_answer_options rao
     JOIN range_answer_option_fields raof ON raof.range_answer_option_id = rao.id
     JOIN rao_lngs ON rao_lngs.range_answer_option_id = rao.id
  WHERE squish_null(raof.option_text::text) IS NOT NULL;
