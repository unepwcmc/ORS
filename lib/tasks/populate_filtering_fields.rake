namespace :db do
  desc "Populate country filtering fields for users of questionnaire"
  task :populate_filtering_fields, [:questionnaire_id, :filtering_field_id] => :environment do |t, args|
    questionnaire = Questionnaire.find(args.questionnaire_id)
    users = questionnaire.authorized_submitters.map(&:user)
    filtering_field_id = args.filtering_field_id
    unless questionnaire.filtering_fields.find_by_id(filtering_field_id)
      Rails.logger.info "FilteringField with id: #{filtering_field_id} not found for this questionnaire"
      filtering_field_id = questionnaire.filtering_fields.find_by_name("Country").try(:id)
    end
    if filtering_field_id
      users.each do |user|
        user_filtering_field = user.user_filtering_fields.
          find_by_filtering_field_id(filtering_field_id)
        if user_filtering_field
          user_filtering_field.update_attributes(field_value: user.country)
          Rails.logger.info "Filtering field #{user_filtering_field.id} value changed to: #{user.country}"
        else
          Rails.logger.info "Creating UserFilteringField for user: "
          Rails.logger.info "ID: #{user.id}, NAME: #{user.first_name} #{user.last_name}"
          UserFilteringField.create({
            user_id: user.id,
            filtering_field_id: filtering_field_id,
            field_value: user.country
          })
        end
      end
    else
      Rails.logger.info "Aborting: 'Country' filtering field not found\n"
      Rails.logger.info "Please be sure that it exists or is named correctly"
    end
  end
end
