class DelegatedLoopItemName < ActiveRecord::Base
  belongs_to :delegation_section
  belongs_to :loop_item_name

  attr_accessible :loop_item_name_id
end

# == Schema Information
#
# Table name: delegated_loop_item_names
#
#  id                    :integer          not null, primary key
#  loop_item_name_id     :integer
#  created_at            :datetime
#  updated_at            :datetime
#  delegation_section_id :integer
#
