require 'csv'

namespace :export do
  task :documents, [:questionnaire_id] => :environment do |t, args|
    questionnaire = Questionnaire.find(args.questionnaire_id)
    documents = questionnaire.documents
    links = questionnaire.answer_links

    header = ["Name", "Link", "Question title", "Question ID", "Respondent", "Country", "Region"]

    documents_filename = "q#{questionnaire.id}_docments.csv"
    links_filename = "q#{questionnaire.id}_links.csv"

    CSV.open(documents_filename, 'w') do |csv|
      csv << header
      documents.each do |doc|
        question = doc.answer.question
        user = doc.answer.user

        q_title = Sanitize.clean(question.title)

        csv << [
          doc.doc_file_name, doc.doc.url, q_title, question.id,
          "#{user.first_name} #{user.last_name}", user.country, user.region
        ]
      end
    end

    CSV.open(links_filename, 'w') do |csv|
      csv << header
      links.each do |link|
        question = link.answer.question
        user = link.answer.user

        q_title = Sanitize.clean(question.title)

        csv << [
          link.title, link.url, q_title, question.id,
          "#{user.first_name} #{user.last_name}", user.country, user.region
        ]
      end
    end

  end
end
