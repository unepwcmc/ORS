class SectionExtra < ActiveRecord::Base

  attr_accessible :extra_id
  
  ###
  ###   Relationships
  ###
  belongs_to :section
  belongs_to :extra
end

# == Schema Information
#
# Table name: section_extras
#
#  id         :integer          not null, primary key
#  section_id :integer
#  extra_id   :integer
#  created_at :datetime
#  updated_at :datetime
#
