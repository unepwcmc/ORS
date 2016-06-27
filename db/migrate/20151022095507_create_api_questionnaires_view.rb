class CreateApiQuestionnairesView < ActiveRecord::Migration
  def up
    sql =<<-EOS
    CREATE OR REPLACE VIEW api_questionnaires_view AS
    WITH q_lngs AS (
      SELECT questionnaire_fields.questionnaire_id,
        array_agg(upper(questionnaire_fields.language::text)) AS languages,
        max(
          CASE
            WHEN questionnaire_fields.is_default_language
            THEN upper(questionnaire_fields.language::text)
            ELSE NULL::text
          END
        ) AS default_language
        FROM questionnaire_fields
        GROUP BY questionnaire_fields.questionnaire_id
    )
    SELECT q.id,
      q.activated_at::date AS activated_on,
      q.questionnaire_date AS questionnaire_date,
      CASE
        WHEN q.status = 0 THEN 'Inactive'::text
        WHEN q.status = 1 THEN 'Active'::text
        WHEN q.status = 2 THEN 'Closed'::text
        ELSE 'Unknown'::text
      END AS status,
      upper(qf.language::text) AS language,
      qf.title,
      qf.is_default_language,
      q_lngs.languages,
      q_lngs.default_language
    FROM questionnaires q
    JOIN questionnaire_fields qf ON qf.questionnaire_id = q.id
    JOIN q_lngs ON q_lngs.questionnaire_id = q.id;
    EOS

    execute sql
  end

  def down
    execute "DROP VIEW api_questionnaires_view"
  end
end
