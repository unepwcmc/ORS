class CopyQuestionShortTitleToUidentifier < ActiveRecord::Migration
  def up
    # This will copy content of short_title from question_fields
    # into questions.uidentifier, with the purpose of using it as
    # an internal reference for the organisation (RAMSAR).
    # uidentifier is a field already present in the database,
    # but without any apparent purpose.
    # short_title is a multilingual field, we take MAX and hope
    # that's the best match.
    execute <<-SQL
    WITH short_titles AS (
      SELECT question_id, MAX(short_title) AS uidentifier
      from question_fields
      group by question_id
    )
    UPDATE questions
    SET uidentifier = short_titles.uidentifier
    FROM short_titles
    WHERE question_id = questions.id
    SQL
  end

  def down
    execute 'UPDATE questions SET uidentifier = NULL'
  end
end
