class QuestionnaireToCsv
  include Sidekiq::Worker
  sidekiq_options queue: "low"

  def perform(user_id, questionnaire_id, separator, respondent_id=nil)
    user          = User.find(user_id)
    questionnaire = Questionnaire.find(questionnaire_id)
    respondent    = User.find(respondent_id) if respondent_id

    return if !user || !questionnaire || (respondent_id && respondent.blank?)

    submitters = respondent.present? ? [respondent] : questionnaire.submitters

    relative_path = "private/questionnaires/#{questionnaire.id.to_s}/"
    relative_path << "#{respondent.id.to_s}/" if respondent.present?
    file_location = "#{Rails.root}/#{relative_path}"
    FileUtils.mkdir_p(file_location) if !File.directory?(file_location)

    file_location << "questionnaire_generating.csv"

    # stop here if a "questionnaire_generating.csv" file is found, created less than
    # 30 minutes ago. This means that an import is already running, and we shouldn't
    # start another one
    if File.exist?(file_location) && File.atime(file_location) > 30.minutes.ago
      return false
    end

    begin
      CsvMethods.fill_csv file_location, submitters, questionnaire.sections, separator

      # move file to the final destination
      csv_file = respondent.present? ? questionnaire.csv_files.find_by_user_id(respondent.id) : questionnaire.csv_file
      file_record = csv_file.presence || CsvFile.new(entity: questionnaire, user: respondent)
      if !file_record.new_record? && File.exist?(file_record.location)
        FileUtils.rm(file_record.location)
      end

      file_record.name = questionnaire.title[0,35].gsub(/[^a-z0-9\-]+/i, '_') + "_#{DateTime.now.strftime("%d%m%Y")}.csv"
      file_record.location = relative_path + file_record.name
      file_record.save

      FileUtils.move(file_location, file_record.location)
      FileUtils.touch file_record.location

      # send notifying e-mail
      UserMailer.csv_file_generated(user, questionnaire).deliver
    rescue => e
      UserMailer.csv_generation_failed(user, questionnaire, e).deliver
      FileUtils.rm(file_location) if File.exists?(file_location)

      Appsignal.add_exception(e)
    end

    true
  end
end
