# Copies a single user's responses between different instances of ORS
# Note the questionnaire strcture must be the same in both instances
# and the questionnaire & user must exist with the same ids in both.
# Additionally, if they've uploaded any documents - this script does not
# handle copying them.
namespace :copy do

  desc "Copy user's responses between insatnces of ORS"
  task :responses, [:questionnaire_id, :user_id, :target_db] => :environment do |t, args|
    
    require 'yaml'
    config = YAML.load_file('config/database.yml')[args.target_db]

    begin
      questionnaire = Questionnaire.find(args.questionnaire_id)
    rescue ActiveRecord::RecordNotFound => e
      message = "Questionnaire #{args.questionnaire_id} not found in source db"
      Rails.logger.warn message
      abort(message)
    end

    begin
      user = User.find(args.user_id)
    rescue ActiveRecord::RecordNotFound => e
      message = "User #{args.user_id} not found in source db"
      Rails.logger.warn message
      abort(message)
    end

    [
      AuthorizedSubmitter,
      User,
      UserDelegate,
      Delegation,
      DelegationSection,
      DelegatedLoopItemName,
      DelegateTextAnswer,
      Answer,
      AnswerPart,
      AnswerPartMatrixOption,
      AnswerLink,
      Document
    ].each do |klass|
      klass_name = klass.name
      klass_cp_name = klass_name + 'Cp'
      klass_cp = Class.new(klass) do
        attr_accessible *column_names
      end
      Object.const_set(klass_cp_name, klass_cp)
      klass_cp.establish_connection(config)
    end

    UserCp.transaction do

      Rails.logger.debug("#{user.user_delegates.count} user_delegates")
      user.user_delegates.each do |user_delegate|
        delegate = user_delegate.delegate
        delegate_cp = user_cp.find_by_email(delegate.email)
        if delegate_cp.nil?
          delegate_cp_attributes = delegate.attributes.
            reject{ |k, v| k == 'id' }
          delegate_cp = UserCp.new(
            delegate_cp_attributes
          ).save(validate: false)
        end
        user_delegate_cp_attributes = user_delegate.attributes.
          reject{ |k, v| k == 'id' }.
          merge({user_id: user.id, delegate_id: delegate_cp.id})
        user_delegate_cp = UserDelegateCp.new(
          user_delegate_cp_attributes
        ).save(validate: false)
        user_delegate.delegations.each do |delegation|
          delegation_cp_attributes = delegation.attributes.
            reject{ |k, v| k == 'id' }.
            merge({user_delegate_id: user_delegate_cp.id})
          delegation_cp = DelegationCp.new(
            delegation_cp_attributes
          ).save(validate: false)
          delegation.delegation_sections.each do |delegation_section|
            delegation_section_cp_attributes = delegation_section.attributes.
              reject{ |k, v| k == 'id' }.
              merge({delegation_id: delegation_cp.id})
            delegation_section_cp = DelegationSectionCp.new(
              delegation_section_cp_attributes
            ).save(validate: false)
            delegation_section.delegated_loop_item_names.each do |delegated_loop_item_name|
              delegated_loop_item_name_cp_attributes = delegated_loop_item_name.attributes.
                reject{ |k, v| k == 'id' }.
                merge({delegation_section_id: delegation_section_cp.id})
              delegated_loop_item_name_cp = DelegatedLoopItemNameCp.new(
                delegated_loop_item_name_cp_attributes
              ).save(validate: false)
            end
          end
        end
      end

      Rails.logger.debug("#{user.answers.count} answers")
      user.answers.where(questionnaire_id: questionnaire.id).each do |answer|
        answer_cp_attributes = answer.attributes.reject{ |k, v| k == 'id' }
        answer_cp = AnswerCp.new(answer_cp_attributes)
        answer_cp.save(validate: false)
        answer.answer_parts.each do |answer_part|
          answer_part_cp_attributes = answer_part.attributes.
            reject{ |k, v| k == 'id' }.
            merge({answer_id: answer_cp.id})
          answer_part_cp = AnswerPartCp.new(
            answer_part_cp_attributes
          ).save(validate: false)
          answer_part.answer_part_matrix_options.each do |answer_part_matrix_option|
            answer_part_matrix_option_cp_attributes = answer_part_matrix_option.attributes.
              reject{ |k, v| k == 'id' }.
              merge({answer_part_id: answer_part_cp.id})
            answer_part_matrix_option_cp = AnswerPartMatrixOptionCp.new(
              answer_part_matrix_option_cp_attributes
            ).save(validate: false)
          end
        end
        answer.answer_links.each do |answer_link|
          answer_link_cp_attributes = answer_link.attributes.
            reject{ |k, v| k == 'id' }.
            merge({answer_id: answer_cp.id})
          answer_link_cp = AnswerLinkCp.new(
            answer_link_cp_attributes
          ).save(validate: false)
        end   
        answer.documents.each do |document|
          document_cp_attributes = document.attributes.
            reject{ |k, v| k == 'id' }.
            merge({answer_id: answer_cp.id})
          document_cp = DocumentCp.new(
            document_cp_attributes
          ).save(validate: false)
          Rails.logger.debug "Copying document #{document.id} as #{document_cp.id} (answer #{answer.id} as #{answer_cp.id})"
        end
        answer.delegate_text_answers.each do |delegate_text_answer|
          user = delegate_text_answer.user
          user_cp = UserCp.find_by_email(user.email)
          delegate_text_answer_cp_attributes = delegate_text_answer.attributes.
            reject{ |k, v| k == 'id' }.
            merge({answer_id: answer_cp.id, user_id: user_cp.id})
          delegate_text_answer_cp = DelegateTextAnswerCp.new(
            delegate_text_answer_cp_attributes
          ).save(validate: false)
        end 
      end

      authorized_submitter = AuthorizedSubmitter.where(
        questionnaire_id: questionnaire.id, user_id: user.id
      ).first
      authorized_submitter_cp = AuthorizedSubmitterCp.where(
        questionnaire_id: questionnaire.id, user_id: user.id
      ).first
      authorized_submitter_cp.status = authorized_submitter.status
      authorized_submitter_cp.updated_at = authorized_submitter.updated_at
      authorized_submitter_cp.save(validate: false)
    end
  end
end
