DROP FUNCTION IF EXISTS clone_questionnaire(
  old_questionnaire_id INTEGER, in_user_id INTEGER,
  clone_answers BOOLEAN
);
CREATE OR REPLACE FUNCTION clone_questionnaire(
  old_questionnaire_id INTEGER, in_user_id INTEGER,
  clone_answers BOOLEAN
) RETURNS INTEGER
LANGUAGE plpgsql AS $$
DECLARE
  new_questionnaire_id INTEGER;
BEGIN
  SELECT * INTO new_questionnaire_id FROM copy_questionnaire(
    old_questionnaire_id, in_user_id
  );
  IF NOT FOUND THEN
    RAISE WARNING 'Unable to clone questionnaire %.', old_questionnaire_id;
    RETURN -1;
  END IF;

  PERFORM copy_authorized_submitters(old_questionnaire_id, new_questionnaire_id);
  PERFORM copy_questionnaire_parts_start(old_questionnaire_id, new_questionnaire_id);

  IF clone_answers THEN
    PERFORM copy_answers_start(old_questionnaire_id, new_questionnaire_id);
  END IF;

  PERFORM copy_questionnaire_parts_end();

  IF clone_answers THEN
    PERFORM copy_answers_end();
  END IF;

  RETURN new_questionnaire_id;
END;
$$;

COMMENT ON FUNCTION clone_questionnaire(
  old_questionnaire_id INTEGER, in_user_id INTEGER,
  clone_answers BOOLEAN
) IS
  'Procedure to create a deep copy of a questionnaire.';
