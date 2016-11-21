namespace :pivot_tables do
  desc "Export multiple answer and numeric question summaries in a single spreadsheet"
  task :generate, [:questionnaire_id] => :environment do |t, args|
    begin
      @questionnaire = Questionnaire.find(args.questionnaire_id)
    rescue ActiveRecord::RecordNotFound => e
      # catch this exception so that retry is not scheduled
      message = "CITES Report #{args.questionnaire_id} not found"
      Rails.logger.warn message
      abort(message)
    end
    PivotTables::Generator.new(@questionnaire).run
  end
end


