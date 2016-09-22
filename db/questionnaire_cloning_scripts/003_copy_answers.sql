DROP FUNCTION IF EXISTS copy_answers(
  old_questionnaire_id INTEGER, new_questionnaire_id INTEGER
);
DROP FUNCTION IF EXISTS copy_answers_start(
  old_questionnaire_id INTEGER, new_questionnaire_id INTEGER
);
CREATE OR REPLACE FUNCTION copy_answers_start(
  old_questionnaire_id INTEGER, new_questionnaire_id INTEGER
) RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
  CREATE TEMP TABLE tmp_answers () INHERITS (answers);
  CREATE TEMP TABLE tmp_documents () INHERITS (documents);
  CREATE TEMP TABLE tmp_answer_links () INHERITS (answer_links);

  INSERT INTO tmp_answers (
    user_id,
    last_editor_id,
    questionnaire_id,
    question_id,
    loop_item_id,
    other_text,
    looping_identifier,
    from_dependent_section,
    created_at,
    updated_at,
    original_id
  )
  SELECT
    user_id,
    last_editor_id,
    new_questionnaire_id,
    question_id,
    loop_item_id,
    other_text,
    looping_identifier,
    from_dependent_section,
    created_at,
    updated_at,
    answers.id
  FROM answers
  WHERE answers.questionnaire_id = old_questionnaire_id;

  -- resolve questions
  UPDATE tmp_answers
  SET question_id = tmp_questions.id
  FROM tmp_questions
  WHERE tmp_questions.original_id = tmp_answers.question_id;

  -- resolve loop items
  UPDATE tmp_answers
  SET loop_item_id = tmp_loop_items.id
  FROM tmp_loop_items
  WHERE tmp_loop_items.original_id = tmp_answers.loop_item_id;

  -- now resolve the amazing looping identifiers
  WITH expanded_looping_identifiers AS (
    -- these subqueries ensure that we know the original order of loop items
    -- within the looping identifier
    SELECT answer_id, arr[pos]::INT AS loop_item_id, pos
    FROM  (
      SELECT *, GENERATE_SUBSCRIPTS(arr, 1) AS pos
      FROM  (
        SELECT id AS answer_id, STRING_TO_ARRAY(looping_identifier, 'S') AS arr
        FROM tmp_answers
      ) x
   ) y
  ), resolved_loop_item_ids AS (
    SELECT t.answer_id, t.loop_item_id, t.pos, tmp_loop_items.id AS new_loop_item_id
    FROM expanded_looping_identifiers t
    JOIN tmp_loop_items
    ON tmp_loop_items.original_id = t.loop_item_id
  ), resolved_looping_identifiers AS (
    SELECT
      resolved_loop_item_ids.answer_id,
      ARRAY_TO_STRING(ARRAY_AGG(new_loop_item_id::TEXT ORDER BY pos), 'S') AS new_looping_identifier
    FROM resolved_loop_item_ids
    GROUP BY answer_id
  )
  UPDATE tmp_answers
  SET looping_identifier = new_looping_identifier
  FROM resolved_looping_identifiers
  WHERE resolved_looping_identifiers.answer_id = tmp_answers.id;

  INSERT INTO tmp_answer_links (
    answer_id,
    url,
    description,
    title,
    created_at,
    updated_at
  )
  SELECT
    tmp_answers.id,
    url,
    description,
    title,
    tmp_answers.created_at,
    tmp_answers.updated_at
  FROM answer_links
  JOIN tmp_answers
  ON tmp_answers.original_id = answer_links.id;

  INSERT INTO tmp_documents (
    answer_id,
    doc_file_name,
    doc_content_type,
    doc_file_size,
    doc_updated_at,
    description,
    created_at,
    updated_at,
    original_id
  )
  SELECT
    tmp_answers.id,
    doc_file_name,
    doc_content_type,
    doc_file_size,
    doc_updated_at,
    description,
    tmp_answers.created_at,
    tmp_answers.updated_at,
    documents.id
  FROM documents
  JOIN tmp_answers
  ON tmp_answers.original_id = documents.answer_id;

  PERFORM copy_answer_parts_start(old_questionnaire_id, new_questionnaire_id);
END;
$$;

DROP FUNCTION IF EXISTS copy_answers_end(
  old_questionnaire_id INTEGER, new_questionnaire_id INTEGER
);
CREATE OR REPLACE FUNCTION copy_answers_end()
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO answers SELECT * FROM tmp_answers;
  DROP TABLE tmp_answers;
  INSERT INTO documents SELECT * FROM tmp_documents;
  DROP TABLE tmp_documents;
  INSERT INTO answer_links SELECT * FROM tmp_answer_links;
  DROP TABLE tmp_answer_links;

  PERFORM copy_answer_parts_end();
END;
$$;
