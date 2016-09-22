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
#  loop_item_name_id     :integer          not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  delegation_section_id :integer
#
