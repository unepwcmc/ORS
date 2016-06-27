-- DROP VIEW api_sections_view;

CREATE OR REPLACE VIEW api_sections_view AS
 WITH s_lngs AS (
         SELECT section_fields_1.section_id,
            array_agg(upper(section_fields_1.language::text)) AS languages
           FROM section_fields section_fields_1
          WHERE squish_null(section_fields_1.title) IS NOT NULL
          GROUP BY section_fields_1.section_id
        )
 SELECT sections.id,
    sections.section_type,
    sections.loop_source_id,
    sections.loop_item_type_id,
    sections.depends_on_question_id,
    sections.depends_on_option_id,
    sections.depends_on_option_value,
    sections.is_hidden,
    sections.display_in_tab,
    strip_tags(section_fields.title) AS title,
    upper(section_fields.language::text) AS language,
    section_fields.is_default_language,
    section_fields.tab_title,
    s_lngs.languages
   FROM sections
     JOIN section_fields ON sections.id = section_fields.section_id
     JOIN s_lngs ON s_lngs.section_id = sections.id
  WHERE squish_null(section_fields.title) IS NOT NULL
  ORDER BY sections.id;
