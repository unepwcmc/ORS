class CloneQuestionnaire
  include Sidekiq::Worker
  sidekiq_options queue: "high"

  def perform(user_id, questionnaire_id, url, copy_answers=false)
    user = User.find(user_id)
    questionnaire = Questionnaire.find(questionnaire_id)

    # Temporarily disable questionnaire duplication for
    # questionnaires which have already been created from another one.
    has_source_questionnaire = questionnaire.original_id.present?

    return if !user || !questionnaire || has_source_questionnaire

    logger = Logger.new("#{Rails.root}/log/sidekiq.log")
    logger.info("#{Time.now}: Started duplication of questionnaire with#{if !copy_answers || copy_answers != "1" then "out" end} answers: #{questionnaire.title}")

    begin
      sql = Questionnaire.send(:sanitize_sql_array, [
        'SELECT * FROM clone_questionnaire(?, ?, ?)',
        questionnaire.id,
        user.id,
        copy_answers
      ])

      pg_result = Questionnaire.connection.execute(sql)
      new_questionnare_id = pg_result.first['clone_questionnaire'].to_i

      if new_questionnare_id < 0
        # if -1 returned, questionnaire has not been copied successfully
        self.errors[:base] << "Cloning failed."
        UserMailer.deliver_questionnaire_duplication_failed(
          user, questionnaire, "Failed when trying to save the questionnaire"
        )
        raise ActiveRecord::Rollback
      end

      new_questionnaire = Questionnaire.find(new_questionnare_id)
      new_questionnaire.questionnaire_parts.each(&:touch)

      logger.info("#{Time.now}: Cloning finished, rebuilding trees")
      QuestionnairePart.rebuild!
      LoopItemType.rebuild!
      LoopItem.rebuild!

      UserMailer.questionnaire_duplicated(user, questionnaire, new_questionnaire, url).deliver
      logger.info("#{Time.now}: Successfully finished duplication of questionnaire with#{if !copy_answers || copy_answers != "1" then "out" end} answers: #{questionnaire.title}")
    rescue => e
      logger.error e.message
      e.backtrace.each{ |l| logger.error l }
      UserMailer.questionnaire_duplication_failed(user, questionnaire, e.message).deliver
      Appsignal.add_exception(e)
    end
  end
end
