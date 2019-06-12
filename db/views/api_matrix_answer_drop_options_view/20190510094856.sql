CREATE OR REPLACE VIEW api_matrix_answer_drop_options_view AS
  WITH mado_lngs AS(
    SELECT madof.matrix_answer_drop_option_id,
           array_agg(upper(madof.language::text)) AS languages
    FROM matrix_answer_drop_option_fields madof
    WHERE madof.option_text::text IS NOT NULL
    GROUP BY madof.matrix_answer_drop_option_id
  )
  SELECT mado.id,
         mado.matrix_answer_id,
         madof.option_text,
         upper(madof.language::text) AS language,
         madof.is_default_language,
         mado_lngs.languages
  FROM matrix_answer_drop_options mado
  JOIN matrix_answer_drop_option_fields madof ON madof.matrix_answer_drop_option_id = mado.id
  JOIN mado_lngs ON mado_lngs.matrix_answer_drop_option_id = mado.id
  WHERE madof.option_text::text IS NOT NULL;
