namespace :db do
  namespace :migrate do
    desc 'Run custom sql scripts'
    task :sql => :environment do
      files = Dir.glob(Rails.root.join('db/questionnaire_cloning_scripts/*.sql'))
      files.sort.each do |file|
        puts file
        ActiveRecord::Base.connection.execute(File.read(file))
      end
    end
  end
  desc 'Overriden the db:migrate task to also run custom sql scripts'
  task :migrate do
    Rake::Task['db:migrate:sql'].invoke
  end
end
