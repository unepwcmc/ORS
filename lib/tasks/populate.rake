namespace :db do
  desc "Handle db"
  task :populate => :environment do
    require 'populator'
    require 'faker'

    puts "::populate:: Task started"
    [User, Questionnaire, Section, Question, TextAnswer, TextAnswerField, MultiAnswer, MultiAnswerOption, Role].each(&:delete_all)
    [ Answer, AnswerPart, SectionField].each(&:delete_all)
    puts "::populate:: Tables' data deleted."

    Role.populate 1 do |role|
      role.name = "admin"
    end
    Role.populate 1 do |role|
      role.name = "respondent"
    end
    Role.populate 1 do |role|
      role.name = "delegate"
    end

    puts "::populate:: Roles successfully created!"

    admin = User.new(:first_name => "Simao", :last_name => "Belchior", :password => "simaob", :password_confirmation => "simaob",
                     :email => "simao.belchior@unep-wcmc.org", :language => "en")
    admin.save!

    admin.roles << Role.all

    puts "::populate:: User #{admin.full_name} created!"

    languages = ["ar", "zh", "en","es", "fr", "ru"]
    (1..25).each do
      language = languages.shuffle.first
      u = User.new(:first_name => Faker::Name.first_name, :last_name => Faker::Name.last_name,
                   :password => "teste1", :password_confirmation => "teste1",
                   :email => Faker::Internet.email, :language => language)
      u.save!
      u.roles << Role.find_by_name("respondent")
    end
    puts "::populate:: Users successfully created!"
    puts "::populate:: Task successfully finished"
  end

  task :clear => :environment do
    puts "::clear:: Task started"
    [ AnswerPart, Answer, Document, UserSectionSubmissionState, AuthorizedSubmitter ].each(&:delete_all)
    puts "::clear:: Submission related Tables' data deleted"
    Questionnaire.all.each do |r|
      if r.active? or r.closed?
        r.status = QuestionnaireStatus::INACTIVE
      end
      r.authorized_submitters.each do |authorized|
        authorized.status = SubmissionStatus::NOT_STARTED
        authorized.save!
      end
      r.save!
      puts "::clear:: Questionnaire #{r.id.to_s} de-activated"
    end
    puts "::clear:: Task successfully finished"
  end
end
