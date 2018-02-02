namespace :export do
  task :users, [:questionnaire_id, :filtering_field_id] => :environment do |t, args|
    questionnaire = Questionnaire.find(args.questionnaire_id)
    filtering_field_id = args.filtering_field_id
    FILTERING_FIELD_NAME = "Ramsar sites by Country"
    unless questionnaire.filtering_fields.find_by_id(filtering_field_id)
      Rails.logger.info "FilteringField with id: #{filtering_field_id} not found for this questionnaire"
      filtering_field_id = questionnaire.filtering_fields.find_by_name(FILTERING_FIELD_NAME).try(:id)
    end
    unless filtering_field_id.present?
      Rails.logger.info "No FilteringField found"
      return
    end
    COLUMNS = ['First name','Last name','Language','Email','Country','Region']
    ATTRIBUTES = COLUMNS.map { |c| c.downcase.tr(' ', '_') }
    File.open('ors_users.csv', 'w') do |file|
      file << "#{COLUMNS.join(',')},Roles,#{FILTERING_FIELD_NAME}\n"
      users = questionnaire.authorized_submitters.map(&:user)
      users.sort_by{ |user| user.first_name }.each do |user|
        user_filtering_field = user.user_filtering_fields.find_by_filtering_field_id(filtering_field_id)
        values = user.attributes.values_at(*ATTRIBUTES)
        roles = user.roles.map(&:name).join(';')
        values << roles
        values << user_filtering_field.try(:field_value)
        file << "#{values.join(',')}\n"
      end
    end
    Rails.logger.info "Export complete!"
  end
end
