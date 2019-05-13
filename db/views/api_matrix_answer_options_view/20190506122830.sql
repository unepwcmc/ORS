CREATE OR REPLACE VIEW api_matrix_answer_options_view AS
  WITH mao_lngs AS(
    SELECT maof.matrix_answer_option_id,
           array_agg(upper(maof.language::text)) AS languages
    FROM matrix_answer_option_fields maof
    WHERE maof.title::text IS NOT NULL
    GROUP BY maof.matrix_answer_option_id
  )
  SELECT mao.id,
         mao.matrix_answer_id,
         maof.title,
         upper(maof.language::text) AS language,
         maof.is_default_language,
         mao_lngs.languages
  FROM matrix_answer_options mao
  JOIN matrix_answer_option_fields maof ON maof.matrix_answer_option_id = mao.id
  JOIN mao_lngs ON mao_lngs.matrix_answer_option_id = mao.id
  WHERE maof.title::text IS NOT NULL;
