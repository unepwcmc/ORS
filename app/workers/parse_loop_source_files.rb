class ParseLoopSourceFiles
  include Sidekiq::Worker
  sidekiq_options queue: "high"

  def perform(user_id, user_ip, loop_source_id)
    begin
      loop_source = LoopSource.find(loop_source_id)
      return if !loop_source
      status = {}
      sources = loop_source
        .source_files.find_all_by_parse_status(ParseFileStatus::TO_PARSE) || []
      sources.each do |source_file_obj|
        if !loop_source.parse_file status, source_file_obj
          status[:errors].each do |error|
            source_file_obj.persistent_errors << PersistentError.create(
              :details => error,
              :user_id => user_id,
              :user_ip => user_ip,
              :timestamp => DateTime.now)
          end
          source_file_obj.parse_status = ParseFileStatus::ERROR_FINISH
        else
          source_file_obj.parse_status = ParseFileStatus::FINISHED
          source_file_obj.persistent_errors.each do |error|
            error.destroy
          end
        end
        source_file_obj.save
      end
    rescue => e
      Appsignal.add_exception(e)
    end
  end
end
