class DelegationSection < ActiveRecord::Base
  belongs_to :delegation
  belongs_to :section
  has_many :delegated_loop_item_names, :include => {:loop_item_name => :loop_item_name_fields}, :dependent => :destroy
  has_many :loop_item_names, :through => :delegated_loop_item_names

  validates_uniqueness_of :delegation_id, :scope => :section_id

  attr_accessible :section_id, :delegation_id

  def add_loop_item_names_from params
    params.each do |loop_item_name_id|
      loop_item_name = LoopItemName.find(loop_item_name_id)
      if loop_item_name && !self.loop_item_names.include?(loop_item_name)
        self.delegated_loop_item_names << DelegatedLoopItemName.create(:loop_item_name_id => loop_item_name.id)
      end
    end
    self.save
  end

  def update_loop_item_names_from params
    existing_loop_item_names = self.loop_item_names
    actual_loop_item_names = []
    params.each do |loop_item_name_id|
      loop_item_name = LoopItemName.find(loop_item_name_id)
      actual_loop_item_names << loop_item_name
      if loop_item_name && !existing_loop_item_names.include?(loop_item_name)
        self.delegated_loop_item_names << DelegatedLoopItemName.create(:loop_item_name_id => loop_item_name.id)
      end
    end
    self.save
    items_to_remove = existing_loop_item_names - actual_loop_item_names
    items_to_remove.each do |item|
      self.delegated_loop_item_names.find_by_loop_item_name_id(item.id).destroy
    end
  end

  def self.create_delegation params, current_user
    delegation_section = nil
    #Create Delegation Section from Questionnaire Submission page
    if params[:delegation].present? && params[:delegation][:user_delegate_id].present?
      user_delegate = UserDelegate.find(params[:delegation][:user_delegate_id])
      section = Section.find(params[:delegation_section][:section_id], :include => :questionnaire_part)
      delegation = user_delegate.delegations.find_by_questionnaire_id(section.questionnaire.id) || Delegation.create(:user_delegate_id => user_delegate.id, :questionnaire_id => section.questionnaire.id, :from_submission => true)
      delegation_section = delegation.delegation_sections.create(params[:delegation_section])
    #Or from the Delegates Dashboard
    elsif params[:delegation_section] && params[:delegation_section][:section_id].present?
      delegation_section_params = params[:delegation_section].merge(delegation_id: params[:delegation_id])
      delegation = Delegation.find(params[:delegation_id])
      delegation_section = DelegationSection.create(delegation_section_params)
      delegation.delegation_sections << delegation_section
    end
    delegation_section
  end
end

# == Schema Information
#
# Table name: delegation_sections
#
#  id            :integer          not null, primary key
#  delegation_id :integer          not null
#  section_id    :integer          not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  original_id   :integer
#
