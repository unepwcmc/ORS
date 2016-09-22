FactoryGirl.define do

  factory :questionnaire_field do
    title Faker::Lorem.sentence(1)
    language ["en", "fr", "es", "zn", "ar", "ru"].shuffle.first
    introductory_remarks Faker::Lorem.sentence(1)
    is_default_language true
  end

  factory :questionnaire do
    questionnaire_date Time.now
    association :user, :factory => :user
    administrator_remarks Faker::Lorem.sentence(4)
  end

  factory :section_field do
    title Faker::Lorem.sentence(1)
    language ["en", "fr", "es", "zn", "ar", "ru"].shuffle.first
    description Faker::Lorem.sentence(5)
    tab_title Faker::Lorem.sentence(1)
  end

  factory :section do
    section_type SectionType.list[Random.rand(SectionType.list.size)]
  end

  factory :question_field do
    title Faker::Lorem.sentence(1)
    language ["en", "fr", "es", "zn", "ar", "ru"].shuffle.first
    description Faker::Lorem.sentence(5)
    short_title Faker::Lorem.sentence(1)
  end

  factory :question do
  end

  factory :question_loop_type do
  end

  factory :questionnaire_part do
    association :part, :factory => [:question, :section].shuffle.first
  end

  factory :answer_type_field do
    help_text "My help"
    language "en"
    is_default_language true
  end

  factory :text_answer do
    after(:create) do |text_answer|
      create(:text_answer_field, :text_answer => text_answer)
    end
  end

  factory :text_answer_field do
    width 30
    rows 5
    association :text_answer
  end

  factory :loop_source do
    name Faker::Lorem.sentence(3)
  end

  factory :source_file do
    source { File.new(Rails.root.join('test', 'csv', 'countries.csv')) }
  end

  factory :loop_item_type do
    #name Faker::Lorem.words(1)
    name "A thingy"
  end

  factory :extra do
    name Faker::Lorem.sentence(1)
    field_type 1
  end

  factory :section_extra do
  end

  factory :loop_item do
  end

  factory :loop_item_name do
    after(:create) do |loop_item_name|
      create(:loop_item_name_field, :loop_item_name => loop_item_name)
    end
  end

  factory :loop_item_name_field do
    item_name Faker::Lorem.words(1)
    language "en"
    is_default_language true
  end

  factory :item_extra do
    after(:create) do |item_extra|
      create(:item_extra_field, :item_extra => item_extra)
    end
  end

  factory :item_extra_field do
    value Faker::Lorem.words(5)
  end

  factory :filtering_field do
    #name Faker::Lorem.words(1)
    name "A filtering_field"
  end

  factory :user_filtering_field do
  end

  factory :user do
    first_name Faker::Name.first_name
    last_name Faker::Name.last_name
    sequence(:perishable_token) { |n| n.to_s + Faker::Internet.password }
    language "en"
    password "simaob"
    password_confirmation "simaob"
    sequence(:email) { |n| n.to_s +  Faker::Internet.email }
  end

  factory :admin, :parent => :user do
    roles { [ FactoryGirl.create(:admin_role) ] }
  end

  factory :respondent, :parent => :user do
    roles { [ FactoryGirl.create(:respondent_role) ] }
  end

  factory :delegate, :parent => :user do
    roles { [ FactoryGirl.create(:delegate_role) ] }
  end

  factory :role do
    sequence(:name) { |n| "role#{n}" }
  end

  factory :admin_role, :parent => :role do
    name "admin"
  end

  factory :respondent_role, :parent => :role do
    name "respondent"
  end

  factory :delegate_role, :parent => :role do
    name "delegate"
  end

  factory :reminder do
    title Faker::Lorem.sentence(1)
    body Faker::Lorem.sentence(5)
    days Random.rand(31)
  end

  factory :alert do
  end

  factory :multi_answer do
    single true
    display_type 1
    after(:create) do |multi_answer|
      create(:multi_answer_option, :multi_answer => multi_answer)
    end
  end

  factory :multi_answer_option do
    after(:create) do |answer_option|
      create(:multi_answer_option_field, :multi_answer_option => answer_option)
    end
  end

  factory :multi_answer_option_field do
    is_default_language true
    language "en"
  end

  factory :other_field do
    other_text 'Other'
    language 'en'
  end

  factory :range_answer do
    after(:create) do |range_answer|
      create(:range_answer_option, :range_answer => range_answer)
    end
  end

  factory :range_answer_option do
    after(:create) do |answer_option|
      create(:range_answer_option_field, :range_answer_option => answer_option)
    end
  end

  factory :range_answer_option_field do
    is_default_language true
    language "en"
  end

  factory :rank_answer do
    after(:create) do |rank_answer|
      create(:rank_answer_option, :rank_answer => rank_answer)
    end
  end

  factory :rank_answer_option do
    after(:create) do |answer_option|
      create(:rank_answer_option_field, :rank_answer_option => answer_option)
    end
  end

  factory :rank_answer_option_field do
    is_default_language true
    language "en"
  end

  factory :numeric_answer do
  end

  factory :matrix_answer do
    matrix_orientation 1
    display_reply InputFieldType::CHECK_BOX
    after(:create) do |matrix_answer|
      create(:matrix_answer_query, :matrix_answer => matrix_answer)
      create(:matrix_answer_option, :matrix_answer => matrix_answer)
    end
  end

  factory :matrix_answer_query do
    after(:create) do |answer_query|
      create(:matrix_answer_query_field, :matrix_answer_query => answer_query)
    end
  end

  factory :matrix_answer_query_field do
    is_default_language true
    language "en"
    title "Derp"
  end

  factory :matrix_answer_option do
    after(:create) do |answer_option|
      create(:matrix_answer_option_field, :matrix_answer_option => answer_option)
    end
  end

  factory :matrix_answer_option_field do
    is_default_language true
    language "en"
    title "Herp"
  end

  factory :matrix_answer_drop_option do
    after(:create) do |answer_drop_option|
      create(:matrix_answer_drop_option_field, :matrix_answer_drop_option => answer_drop_option)
    end
  end

  factory :matrix_answer_drop_option_field do
    is_default_language true
    language "en"
  end

  factory :deadline do
    title "My default deadline title"
    soft_deadline true
    due_date Date.new(2015, 12, 3)
  end

  factory :answer do
  end

  factory :answer_part do
  end

  factory :answer_link do
    url Faker::Internet.url
  end

  factory :document do
    doc { File.new(Rails.root.join('app', 'assets', 'images', 'wcmc_logo.png')) }
  end

  factory :answer_part_matrix_option do
  end

  factory :user_delegate do
  end

  factory :delegation do
  end

  factory :delegation_section do
  end

  factory :delegated_loop_item_name do
  end

  factory :user_section_submission_state do
    section_state 0
  end

  factory :tag, class: ActsAsTaggableOn::Tag do
    name Faker::Lorem.words(1)
  end

  factory :tagging, class: ActsAsTaggableOn::Tagging do
    context 'groups'
    taggable_type 'User'
  end

end
