require 'sidekiq/web'
OnlineReportingTool::Application.routes.draw do
  match 'signup' => 'users#new', :as => :signup
  match 'logout' => 'user_sessions#destroy', :as => :logout
  match 'login' => 'user_sessions#new', :as => :login
  match 'administration/' => 'administration#index', :as => :administration
  match 'respondent_admin/' => 'respondent_admin#index', as: :respondent_admin
  match 'loop_sources/:id/item_types/:parent_id' => 'loop_sources#item_types', :as => :loop_source_item_types
  match 'loop_sources/:id/item_types/edit/:section_id' => 'loop_sources#item_types', :as => :loop_source_item_types
  match 'questionnaires/:questionnaire_id/authorized_submitters/add/:users' => 'authorized_submitters#add', :as => :authorize_submitter, :method => 'post'
  match 'questionnaires/:questionnaire_id/authorized_submitters/remove/:user_id' => 'authorized_submitters#remove', :as => :remove_authorized_submitter, :method => 'post'
  match 'questionnaires/empty_text_answers_report' => 'questionnaires#empty_text_answers_report', as: :empty_text_answers_report

  mount Sidekiq::Web => '/sidekiq'

  resources :alerts
  resources :answer_parts

  get 'answers/:answer_id/documents/:id', to: 'documents#show'

  resources :answers do
    member do
      get :add_links
      get :add_document
    end
  end

  resources :authorized_submitters
  resources :deadlines do
    resources :alerts
  end
  resources :delegation_sections

  resources :extras do
    member do
      get :new_source
      post :upload_source
    end
  end

  resources :home

  resources :loop_items
  resources :loop_item_names
  resources :loop_item_types do
    resources :extras, :shallow => true
    member do
      post :upload_item_names_source
    end
  end

  resources :loop_sources do
    member do
      get :fill_jqgrid
      post :jqgrid_update
    end
  end

  resources :matrix_answers
  resources :multi_answers
  resources :numeric_answers
  resources :questions do
    member do
      get :preview
      get :dependency_options
      get :delete
      get :answers
    end
  end

  resources :questionnaires do
    resources :authorized_submitters
    resources :loop_sources
    resources :questionnaire_parts
    resources :filtering_fields
    resources :deadlines
    resources :unsubmission_requests

    collection do
      get :active
      get :duplicate
      get :search
    end

    member do
      get :preview
      put :activate
      put :deactivate
      get :tree
      get :delete
      get :to_pdf
      get :submission
      put :submit
      put :unsubmit
      get :respondents
      put :close
      put :open
      get :to_csv
      get :download_csv
      get :generate_pivot_tables
      get :download_pivot_tables
      get :structure_ordering
      get :jstree
      put :move_questionnaire_part
      post :send_multiple_deadline_warnings
      get :manage_languages
      post :update_languages
      get :dashboard
      get :communication_details
      get :sections
    end

    match 'send_deadline_warning/:user_id' => 'questionnaires#send_deadline_warning', as: :send_deadline_warning
    match 'download_user_pdf/:user_id' => 'questionnaires#download_user_pdf', as: :download_user_pdf
  end

  resources :questionnaire_parts do
    member do
      get :part_can_be_moved
      get :node_move_information
    end
  end

  resources :range_answers
  resources :rank_answers
  resources :reminders

  resources :sections do
    member do
      get :preview
      get :define_dependency
      post :set_dependency
      delete :unset_dependency
      get :questions
      get :questions_for_dependency
      get :delete
      get :submission
      get :load_lazy
      get :loop_item_names
      get :to_csv
      get :download_csv
    end
  end

  resources :source_files
  resources :text_answers

  resources :user_delegates do
    member do
      get :dashboard
    end

    resources :delegations do
      resources :delegation_sections
    end
  end

  #resources :user_delegates do
  #  resources :delegations
  #end

  resources :users do
    collection do
      get :add_list
      post :upload_list
      get :add_new_user
      post :create_new_user
    end

    member do
      get :delete
      get :update_submission_page
      put :remove_group
    end

    resources :user_delegates do
      member do
        get :dashboard
      end

      resources :delegations do
        resources :delegation_sections
      end
    end

  end

  resources :application_profile, only: [:index, :update]

  resources :delegations do
    resources :delegation_sections
  end
  resources :user_sessions

  resources :password_resets, only: [:new, :create, :edit, :update ]

  root to: "home#index"
  match '/' => 'home#index'
  match '/:controller(/:action(/:id))'
end
