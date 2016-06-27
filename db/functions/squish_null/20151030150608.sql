CREATE OR REPLACE FUNCTION squish(TEXT) RETURNS TEXT
  LANGUAGE SQL IMMUTABLE
  AS $$
    SELECT BTRIM(
      regexp_replace(
        regexp_replace($1, U&'\00A0', ' ', 'g'),
        E'\\s+', ' ', 'g'
      )
    );
  $$;

COMMENT ON FUNCTION squish(TEXT) IS
  'Squishes whitespace characters in a string';


CREATE OR REPLACE FUNCTION squish_null(TEXT) RETURNS TEXT
  LANGUAGE SQL IMMUTABLE
  AS $$
    SELECT CASE WHEN SQUISH($1) = '' THEN NULL ELSE SQUISH($1) END;
  $$;

COMMENT ON FUNCTION squish_null(TEXT) IS
  'Squishes whitespace characters in a string and returns null for empty string';
