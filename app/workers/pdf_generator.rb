class PdfGenerator
  include Sidekiq::Worker
  sidekiq_options queue: "high"

  def perform(requester_id, user_id, questionnaire_id, url_prefix, short_version)
    begin
      user = User.find(user_id)
      questionnaire = Questionnaire.find(questionnaire_id)
      requester = requester_id == user_id ? user : User.find(requester_id)
      QuestionnairePdf.new.to_pdf requester, user, questionnaire, url_prefix, short_version
    rescue => e
      Appsignal.add_exception(e)
    end
  end
end
