CREATE OR REPLACE VIEW api_matrix_answer_queries_view AS
  WITH maq_lngs AS(
    SELECT maqf.matrix_answer_query_id,
           array_agg(upper(maqf.language::text)) AS languages
    FROM matrix_answer_query_fields maqf
    WHERE maqf.title::text IS NOT NULL
    GROUP BY maqf.matrix_answer_query_id
  )
  SELECT maq.id,
         maq.matrix_answer_id,
         maqf.title,
         upper(maqf.language::text) AS language,
         maqf.is_default_language,
         maq_lngs.languages
  FROM matrix_answer_queries maq
  JOIN matrix_answer_query_fields maqf ON maqf.matrix_answer_query_id = maq.id
  JOIN maq_lngs ON maq_lngs.matrix_answer_query_id = maq.id
  WHERE maqf.title::text IS NOT NULL;
