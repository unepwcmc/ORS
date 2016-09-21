class SectionToCsv
  include Sidekiq::Worker
  sidekiq_options queue: "low"

  def perform(user_id, section_id, separator)
    user = User.find(user_id)
    section = Section.find(section_id)
    questionnaire = section.questionnaire

    return if !user || !section || !questionnaire

    file_location = "#{Rails.root}/private/questionnaires/#{questionnaire.id}/sections/#{section.id}/"
    if !File.directory? file_location
      FileUtils.mkdir_p(file_location)
    end
    file_location << "section_generating.csv"

    if File.exist?(file_location) && File.atime(file_location) < 30.minutes.ago
      return false
    end

    begin
      CsvMethods.fill_csv file_location, questionnaire.submitters, section, separator

      # move file to the final destination
      file_record = section.csv_file || CsvFile.new(:entity => section)
      if !file_record.new_record? && File.exist?(file_record.location)
        FileUtils.rm(file_record.location)
      end
      file_record.name = Sanitize.clean(section.title, {})[0,55] + "_#{DateTime.now.strftime("%d%m%Y")}.csv"
      file_record.location = "private/questionnaires/#{questionnaire.id}/sections/#{section.id}/"+ file_record.name
      file_record.save

      FileUtils.move(file_location, file_record.location)
      FileUtils.touch file_record.location

      # send notifying e-mail
      UserMailer.csv_file_generated(user, questionnaire, section).deliver
    rescue => e
      UserMailer.csv_generation_failed(user, questionnaire, e, section).deliver

      if File.exist?(file_location)
        FileUtils.rm(file_location)
      end
      Appsignal.add_exception(e)
    end
    true
  end
end
