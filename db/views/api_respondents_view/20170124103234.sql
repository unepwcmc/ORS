CREATE OR REPLACE VIEW api_respondents_view AS
 SELECT authorized_submitters.id,
    users.id AS user_id,
    users.country,
    users.region,
    authorized_submitters.questionnaire_id,
    (users.first_name::text || ' '::text) || users.last_name::text AS full_name,
        CASE
            WHEN authorized_submitters.status = 0 THEN 'Not started'::text
            WHEN authorized_submitters.status = 1 THEN 'Underway'::text
            WHEN authorized_submitters.status = 2 THEN 'Submitted'::text
            WHEN authorized_submitters.status = 3 THEN 'Halted'::text
            ELSE 'Unknown'::text
        END AS status,
    authorized_submitters.status AS status_code
   FROM authorized_submitters
     JOIN users ON users.id = authorized_submitters.user_id;