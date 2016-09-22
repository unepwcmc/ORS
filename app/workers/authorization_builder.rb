class AuthorizationBuilder
  include Sidekiq::Worker
  sidekiq_options queue: "critical"

  def perform(user_id, questionnaire_id, url, disable_emails)
    begin
      questionnaire = Questionnaire.find(questionnaire_id)
      user = User.find(user_id)
      logger = Logger.new("#{Rails.root}/log/sidekiq.log")
      logger.info("#{Time.now}: Building submission states of questionnaire: #{questionnaire.title}, for user #{user.full_name}")
      questionnaire.sections.each do |s|
        loop_sources_items = {}
        if s.looping?
          items = s.loop_item_type.loop_items
          items.each do |item|
            loop_sources_items[s.loop_source_id.to_s] = item
            s.initialise_tree_submission_states(user, loop_sources_items, item, item.id.to_s)
          end
        else
          s.initialise_tree_submission_states(user, loop_sources_items, nil)
        end
      end
      authorization = user.authorized_submitters.find_by_questionnaire_id(questionnaire.id)
      authorization.status = SubmissionStatus::UNDERWAY
      authorization.save
      UserMailer.authorisation_granted(user, questionnaire, url).deliver unless disable_emails == "on"
      logger.info("#{Time.now}: Built submission states of questionnaire: #{questionnaire.title}, for user #{user.full_name}.")
      logger.info(" User has been notified through email to: #{user.email}") unless disable_emails == "on"
    rescue => e
      Appsignal.add_exception(e)
    end
  end

end
