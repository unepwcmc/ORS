-- DROP VIEW api_sections_tree_view;

CREATE OR REPLACE VIEW api_sections_tree_view AS
 WITH RECURSIVE section_qparts_with_descendents AS (
         SELECT h.questionnaire_id,
            h.id AS qp_id,
            h.parent_id AS qp_parent_id,
            ARRAY[s.title] AS path,
            s.id,
            NULL::integer AS parent_id,
            s.section_type,
            s.loop_source_id,
            s.loop_item_type_id,
                CASE
                    WHEN s.loop_item_type_id IS NOT NULL THEN s.id
                    ELSE NULL::integer
                END AS looping_section_id,
            s.depends_on_question_id,
            s.depends_on_option_id,
            s.depends_on_option_value,
            s.is_hidden,
            s.display_in_tab,
            s.title,
            s.language,
            s.is_default_language,
            s.tab_title,
            s.languages
           FROM questionnaire_parts h
             JOIN api_sections_view s ON h.part_id = s.id AND h.part_type::text = 'Section'::text
          WHERE h.parent_id IS NULL
        UNION
         SELECT h.questionnaire_id,
            hi.id AS qp_id,
            hi.parent_id AS qp_parent_id,
            h.path || ARRAY[s.title],
            s.id,
            h.id AS parent_id,
            s.section_type,
            s.loop_source_id,
            COALESCE(s.loop_item_type_id, h.loop_item_type_id) AS "coalesce",
            COALESCE(
                CASE
                    WHEN s.loop_item_type_id IS NOT NULL THEN s.id
                    ELSE NULL::integer
                END, h.looping_section_id) AS "coalesce",
            s.depends_on_question_id,
            s.depends_on_option_id,
            s.depends_on_option_value,
            s.is_hidden,
            s.display_in_tab,
            s.title,
            s.language,
            s.is_default_language,
            s.tab_title,
            s.languages
           FROM questionnaire_parts hi
             JOIN api_sections_view s ON hi.part_id = s.id AND hi.part_type::text = 'Section'::text
             JOIN section_qparts_with_descendents h ON h.qp_id = hi.parent_id AND h.language = s.language
        )
 SELECT qp.questionnaire_id,
    qp.qp_id,
    qp.qp_parent_id,
    qp.path,
    qp.id,
    qp.parent_id,
    qp.section_type,
    qp.loop_source_id,
    qp.loop_item_type_id,
    qp.looping_section_id,
    qp.depends_on_question_id,
    qp.depends_on_option_id,
    qp.depends_on_option_value,
    qp.is_hidden,
    qp.display_in_tab,
    qp.title,
    qp.language,
    qp.is_default_language,
    qp.tab_title,
    qp.languages
   FROM section_qparts_with_descendents qp;
