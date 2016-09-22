# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  include Authentication

  helper :all # include all helpers, all the time

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => '43fc56c4a7e41d3ba8621d6ee12aa766'

  before_filter :set_locale

  # See ActionController::Base for details
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password").
  #filter_parameter_logging :password, :password_confirmation

  unless Rails.application.config.consider_all_requests_local
    rescue_from Exception,                            :with => :render_error
    rescue_from ActiveRecord::RecordNotFound,         :with => :render_not_found
    rescue_from ActionController::RoutingError,       :with => :render_not_found
    rescue_from ActionController::UnknownController,  :with => :render_not_found
    rescue_from ActionController::UnknownAction,      :with => :render_not_found
  end
  rescue_from CanCan::AccessDenied,                 :with => :cancan_error

  private
  def set_locale
    if ( logged_in? and current_user.language.present? )
      I18n.locale = current_user.language
    elsif params[:lang].present?
      I18n.locale = params[:lang]
    else
      I18n.locale = "en"
    end
  end

  def render_not_found(exception)
    Rails.logger.warn(exception)
    render :template => "/errors/404.html.erb", :status => 404, :layout => false
  end

  def render_error(exception)
    Rails.logger.warn(exception)
    Appsignal.add_exception(exception)
    render :template => "errors/500.html.erb", :status => 500, :layout => false
  end

  def cancan_error(exception)
    flash[:error] = exception.message
    respond_to do |format|
      format.html  { redirect_to root_path }
      format.js {
        if ["save_answers", "submission", "load_lazy", "add_document", "add_links"].include?(request[:action]) || (request[:controller] == "answers" && request[:action == "update"])
          render :partial => "layouts/authorization_denied_with_redirect"
        else
          render :partial => 'layouts/authorization_denied'
        end
      }
    end
  end

  def clean_answer_types_from params
    if params[:answer_type]
      params[:answer_type][:text_answer_fields_attributes].delete(:new_text_answer_fields) if params[:answer_type][:text_answer_fields_attributes]
      params[:answer_type][:multi_answer_options_attributes].delete(:new_multi_answer_options) if params[:answer_type][:multi_answer_options_attributes]
      params[:answer_type][:rank_answer_options_attributes].delete(:new_rank_answer_options) if params[:answer_type][:rank_answer_options_attributes]
      params[:answer_type][:matrix_answer_queries_attributes].delete(:new_matrix_answer_queries) if params[:answer_type][:matrix_answer_queries_attributes]
      params[:answer_type][:matrix_answer_options_attributes].delete(:new_matrix_answer_options) if params[:answer_type][:matrix_answer_options_attributes]
      params[:answer_type][:matrix_answer_drop_options_attributes].delete(:new_matrix_answer_drop_options) if params[:answer_type][:matrix_answer_drop_options_attributes]
      params[:answer_type][:range_answer_options_attributes].delete(:new_range_answer_options) if params[:answer_type][:range_answer_options_attributes]
    end
  end

  def update_questionnaire_last_editor questionnaire, user
    questionnaire.last_editor_id = user.id
    questionnaire.save
  end

  def set_current_user_delegate
    @current_user_delegate = UserDelegate.find(params[:user_delegate]) if params[:user_delegate].present?
  end
end
