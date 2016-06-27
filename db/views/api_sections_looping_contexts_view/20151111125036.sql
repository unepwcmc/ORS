-- DROP VIEW api_sections_looping_contexts_view;

CREATE OR REPLACE VIEW api_sections_looping_contexts_view AS
 WITH RECURSIVE li_tree(li_id, li_parent_id, section_id, li_lft, li_context, lin_context, language) AS (
         SELECT li.id,
            li.parent_id,
            s_1.id,
            li.lft,
            ARRAY[li.id] AS "array",
            ARRAY[linf.item_name]::text[] AS "array",
            upper(linf.language::text) AS upper
           FROM loop_items li
             JOIN sections s_1 ON s_1.loop_item_type_id = li.loop_item_type_id
             JOIN loop_item_names lin ON lin.id = li.loop_item_name_id
             JOIN loop_item_name_fields linf ON linf.loop_item_name_id = lin.id
          WHERE li.parent_id IS NULL
        UNION ALL
         SELECT li.id,
            li.parent_id,
            s_1.id,
            li.lft,
            li_tree_1.li_context || ARRAY[li.id],
            li_tree_1.lin_context || ARRAY[linf.item_name]::text[],
            upper(linf.language::text) AS upper
           FROM loop_items li
             JOIN li_tree li_tree_1 ON li.parent_id = li_tree_1.li_id
             JOIN sections s_1 ON s_1.loop_item_type_id = li.loop_item_type_id
             JOIN loop_item_names lin ON lin.id = li.loop_item_name_id
             JOIN loop_item_name_fields linf ON linf.loop_item_name_id = lin.id AND upper(linf.language::text) = li_tree_1.language
        )
 SELECT s.id AS section_id,
    s.language,
    array_to_string(li_tree.li_context, 'S'::text) AS looping_identifier,
    li_tree.lin_context AS looping_context,
    li_tree.li_lft
   FROM api_sections_tree_view s
     JOIN li_tree ON s.looping_section_id = li_tree.section_id AND s.language = li_tree.language;
