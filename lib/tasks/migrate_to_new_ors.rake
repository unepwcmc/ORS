## Sample
# Just Questionnaire ID 56
# RAILS_ENV=production rake migrate_to_new_ors['https://ors.cms.int',56]

# All questionnaires
# RAILS_ENV=production rake migrate_to_new_ors['https://ors.cms.int']
task :migrate_to_new_ors, [:url_prefix, :questionnaire_id] => :environment do |t, args|
  puts "Environment: #{Rails.env}"

  # Boolean for debugging.
  export_csv = true
  export_pdf = true
  export_loop_source = true
  export_document = true

  scope =
    if args.questionnaire_id.blank?
      Questionnaire
    else
      Questionnaire.where(id: args.questionnaire_id)
    end

  url_prefix = args.url_prefix # Sample 'https://ors.cms.int'
  abort("ERROR: Missing url_prefix") if url_prefix.blank?

  export_user = User.find_by_email('orsteam@unep-wcmc.org')
  abort "ERROR: orsteam@unep-wcmc.org not found" if export_user.nil?

  # Ensure no "generating" placeholder file.
  # If there is any, ensure no sidekiq job is running, then safe to remove that file.
  output = `find #{Rails.root}/private -type f -name "*generating*"`
  abort "ERROR: some 'generating' file exists:\n #{output}" if output.present?

  # Create our working directory.
  working_dir = FileUtils.mkdir_p("#{Rails.root}/private/migrate_to_new_ors").first

  Dir.chdir(working_dir) do
    scope.find_each do |questionnaire|
      puts "Questionnaire #{questionnaire.id}.............................BEGIN"
      # Create questionnaire directory.
      questionnaire_dir = FileUtils.mkdir_p("questionnaire_#{questionnaire.id}").first
      Dir.chdir(questionnaire_dir) do
        # Questionnaire CSV, with all answers, for Secretariat.
        # both , and ; separator
        if export_csv
          [{:name => 'comma', :symbol => ','}, {:name => 'semicolon', :symbol => ';'}].each do |separator|
            puts "..Export CSV separator #{separator[:name]}"
            # Export it using original sidekiq job.
            success = QuestionnaireToCsv.new.perform(export_user.id, questionnaire.id, separator[:symbol])
            abort "..ERROR: Export questionnaire #{questionnaire.id} CSV separator #{separator[:name]} failed" unless success

            # Copy the export file to our directory, and rename it.
            csv_file = questionnaire.reload.csv_file
            # Remove .csv at the end of the filename, append "_separator_comma.csv"
            new_filename = "#{csv_file.name[0..-5]}_separator_#{separator[:name]}.csv"
            FileUtils.cp(csv_file.location, File.join(working_dir, questionnaire_dir, new_filename))
          end
        end

        # Preview PDF, for Secretariat.
        if export_pdf
          puts "..Export preview PDF"
          File.open(File.join(working_dir, questionnaire_dir, 'preview.pdf'), "wb") do |file|
            file.write(QuestionnairePdf.new.preview_pdf(questionnaire))
          end
        end

        # LoopSource source files
        if export_loop_source && questionnaire.loop_sources.count > 0
          puts "..Export LoopSource source files"
          questionnaire.loop_sources.each do |loop_source|
            loop_source.source_files.each do |source_file|
              source_file_path = source_file.source.path
              if File.exist?(source_file_path)
                loop_source_dir = FileUtils.mkdir_p("loop_sources/#{loop_source.id}").first
                new_filename = "#{source_file.id}_#{source_file.source.original_filename}"
                FileUtils.cp(source_file_path, File.join(working_dir, questionnaire_dir, loop_source_dir, new_filename))
              end
            end
          end
        end

        # For Respondent
        if export_pdf || export_document
        users_dir = FileUtils.mkdir_p("users").first
        Dir.chdir(users_dir) do
          questionnaire.submitters.find_each do |respondent|
              puts "..Export respondent #{respondent.id}"
              # Create user dir.
              respondent_dir = FileUtils.mkdir_p(respondent.id.to_s).first

              # Both long and short PDF.
              if export_pdf
                ['short', 'long'].each do |long_or_short|
                  puts "....Export answer PDF #{long_or_short}"
                  short_version = long_or_short == 'short'

                  # Export it using original way.
                  QuestionnairePdf.new.to_pdf(export_user, respondent, questionnaire, url_prefix, short_version)
                  pdf_file = questionnaire.pdf_files.find_by_user_id_and_is_long(respondent.id, !short_version)

                  # Copy the export file to our directory.
                  FileUtils.cp(pdf_file.location, respondent_dir)
                end
              end

              # All attachments of this questionnaire x respondent
              if export_document
                documents = Document.where(answer_id: questionnaire.answers.where(user_id: respondent.id).select(:id))
                if documents.count > 0
                  puts "....Export documents"
                  Dir.chdir(respondent_dir) do
                    # Create respondent's 'documents' dir.
                    respondent_doc_dir = FileUtils.mkdir_p("documents").first
                    documents.each do |document|
                      # Copy the export file to our directory.
                      FileUtils.cp(document.doc.path, respondent_doc_dir)
                    end
                  end
                end
              end
            end # respodnents loop
          end # users dir
        end

      end # Questionnaire working dir
      puts "Questionnaire #{questionnaire.id}.............................END"
    end # Questionnaire loop
  end # Working dir
end
