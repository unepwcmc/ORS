class FilteringField < ActiveRecord::Base

  has_many :loop_item_types, :dependent => :nullify
  belongs_to :questionnaire
  has_many :user_filtering_fields, :dependent => :destroy
  has_many :users, :through => :user_filtering_fields

  attr_accessible :name

  def get_all_loop_item_names_and_source_info
    loop_item_names = {}
    self.loop_item_types.each do |loop_item_type|
      loop_item_type.loop_item_names.each do |loop_item_name|
        loop_item_names[loop_item_name.item_name] ||= []
        loop_item_names[loop_item_name.item_name] << loop_item_name
      end
    end
    loop_item_names.sort
  end

  def get_unique_loop_item_names
    loop_item_names = []
    self.loop_item_types.each do |loop_item_type|
      loop_item_names += loop_item_type.loop_item_names.map{|a| a.item_name}
    end
    downcased = []
    loop_item_names.inject([]) { |result,h|
      unless downcased.include?(h.downcase);
        result << h
        downcased << h.downcase
      end;
      result}.sort
  end
end

# == Schema Information
#
# Table name: filtering_fields
#
#  id               :integer          not null, primary key
#  name             :string(255)
#  questionnaire_id :integer
#  created_at       :datetime
#  updated_at       :datetime
#  original_id      :integer
#
