class UserMailer < ActionMailer::Base
  default from: "no-reply@unep-wcmc.org"
  default content_type: "text/html"

  def registration_confirmation(user, url)
    I18n.locale = user.language
    @user = user
    @url = url
    mail(
      to: user.email,
      subject: I18n.t('user_mailer.user_registration.subject')
    )
  end

  def user_registration(user, password, url)
    I18n.locale = user.language
    @user = user
    @password = password
    @url = url
    mail(
      to: @user.email,
      subject: I18n.t('user_mailer.new_respondent.subject')
    )
  end

  def admin_notification_registration_confirmation(admin, user)
    I18n.locale = admin.language
    @user = user
    @admin = admin
    mail(
      to: admin.email,
      subject: I18n.t('user_mailer.new_user_registered')
    )
  end

  def authorisation_granted(user, questionnaire, url)
    I18n.locale = user.language
    @user = user
    @url = url
    @questionnaire = questionnaire
    mail(
      to: user.email,
      subject: (questionnaire.email_subject(user.language) ? questionnaire.email_subject(user.language) + " - " : "")+ I18n.t('user_mailer.authorisation_granted.subject')
    )
  end

  def questionnaire_submitted(user, questionnaire)
    I18n.locale = user.language
    @user = user
    @questionnaire = questionnaire
    mail(
      to: user.email,
      subject: (questionnaire.email_subject(user.language) ? questionnaire.email_subject(user.language) + " - " : "") + I18n.t('user_mailer.questionnaire_submitted.subject')
    )
  end

  def admin_notification_questionnaire_submitted(user, questionnaire)
    admin = questionnaire.user
    I18n.locale = admin.language
    @user = user
    @questionnaire = questionnaire
    mail(
      to: admin.email,
      subject: (questionnaire.email_subject(user.language) ? questionnaire.email_subject(user.language) + " - " : "") + I18n.t('user_mailer.questionnaire_submitted.admin_subject') + " " + user.full_name
    )
  end

  def request_unsubmission(user, questionnaire, subject, msg, url)
    admin = questionnaire.user
    I18n.locale = admin.language
    @user = user
    @url = url
    @questionnaire = questionnaire
    @msg = msg
    mail(
      to: admin.email,
      url: @url,
      subject: "#{ApplicationProfile.title} Unsubmission request"
    )
  end

  #TODO: localise
  def questionnaire_due_warning(user, questionnaire, deadline, url)
    @user = user
    @questionnaire = questionnaire
    @deadline = deadline
    @url = url
    mail(
      to: user.email,
      subject: "#{questionnaire.email_subject(user.language) ? questionnaire.email_subject(user.language) : ""} Questionnaire due on #{deadline.strftime("%H:%M:%S %B %d, %Y")}"
    )
  end

  def contact_questionnaire_users(user, subject_text, body_text)
    @user = user
    @subject_text = subject_text
    @body_text = body_text
    mail(
      to: user.email,
      subject: subject_text
    )
  end

  def pdf_generated(requester, questionnaire, user)
    I18n.locale = requester.language
    @user = user
    @questionnaire = questionnaire
    @requester = requester
    mail(
      to: requester.email,
      subject: (questionnaire.email_subject(requester.language) ? questionnaire.email_subject(requester.language) + " - " : "") + I18n.t('user_mailer.pdf_generated.subject')
    )
  end

  def pdf_generation_failed(requester, user, questionnaire, error_message)
    I18n.locale = requester.language
    @user = user
    @questionnaire = questionnaire
    @requester = requester
    @error_message = error_message
    mail(
      to: requester.email,
      subject: (questionnaire.email_subject(requester.language) ? questionnaire.email_subject(requester.language) + " - " : "") + I18n.t('user_mailer.pdf_generation_failed.subject')
    )
  end

  def csv_file_generated(user, questionnaire, section=nil)
    I18n.locale = user.language
    @user = user
    @questionnaire = questionnaire
    @section = section
    mail(
      to: user.email,
      subject: (questionnaire.email_subject(user.language) ? questionnaire.email_subject(user.language) + " - " : "") + I18n.t('user_mailer.csv_file_generated.subject')
    )
  end

  def csv_generation_failed(user, questionnaire, error, section=nil)
    I18n.locale = user.language
    @user = user
    @questionnaire = questionnaire
    @section = section
    @error = error
    mail(
      to: user.email,
      subject: (questionnaire.email_subject(user.language) ? questionnaire.email_subject(user.language) + " - " : "") + I18n.t('user_mailer.csv_generation_failed.subject')
    )
  end

  def delegate_request(user_delegate)
    I18n.locale = user_delegate.delegate.language
    @user_delegate = user_delegate
    mail(
      to: user_delegate.delegate.email,
      subject: I18n.t('user_mailer.delegate_request.subject')
    )
  end

  #TODO message template
  def user_registered_by_delegate_request(user_delegate, password)
    recipients user_delegate.delegate.email
    @user = user_delegate
    mail(
      to: user_delegate.delegate.email,
      subject: "[#{ApplicationProfile.title}] You have been added to the system"
    )
  end

  # Rails 3 compatible.
  def delegate_registration(user, password, url)
    I18n.locale = user.language
    @user = user
    @password = password
    @url = url
    @password = password
    mail(
      to: @user.email,
      subject: I18n.t('user_mailer.delegate_registration.subject'),
      content_type: "text/html"
    )
  end

  # Rails 3 compatible.
  def section_delegated(delegation_section, url)
    @user = delegation_section.delegation.delegate
    @delegation_section = delegation_section
    @url = url
    I18n.locale = @user.language
    mail(
      to: @user.email,
      subject: (delegation_section.delegation.questionnaire.email_subject(@user.language) ? delegation_section.delegation.questionnaire.email_subject(@user.language) : "") + I18n.t('user_mailer.section_delegated.subject'),
      content_type: "text/html"
    )
  end

  # Rails 3 compatible.
  def questionnaire_delegated(delegate, delegator, delegation, url)
    @delegate = delegate
    @delegator = delegator
    @delegation = delegation
    I18n.locale = @delegate.language
    @url = url
    mail(
      to: @delegate.email,
      subject: (@delegation.questionnaire.email_subject(@delegate.language) ? @delegation.questionnaire.email_subject(@delegate.language) : "") + I18n.t('user_mailer.questionnaire_delegated.subject'),
      content_type: "text/html"
    )
  end

  def questionnaire_duplicated(user, questionnaire, new_questionnaire, url)
    I18n.locale = user.language
    @user = user
    @questionnaire = questionnaire
    @new_questionnaire = new_questionnaire
    @url = url
    mail(
      to: user.email,
      subject: (( questionnaire.email_subject(user.language) ? questionnaire.email_subject(user.language) : "" ) + I18n.t('user_mailer.questionnaire_duplicated.subject'))
    )
  end

  # Rails 3 compatible.
  # TODO: needs testing!
  def questionnaire_duplication_failed(user, questionnaire, error_message)
    I18n.locale = user.language
    @questionnaire = questionnaire
    @user = user
    @error_message = error_message
    @subject = (questionnaire.email_subject(user.language) ? questionnaire.email_subject(user.language) : "") + I18n.t('user_mailer.questionnaire_duplication_failed.subject')
    mail(
      to: @user.email,
      subject: @subject
    )
  end

  def deliver_password_reset_instructions(user)
    @user = user
    mail(to: user.email, subject: "Online Reporting System - password reset instructions" )
  end
end
