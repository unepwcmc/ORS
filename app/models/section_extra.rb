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
#  section_id :integer          not null
#  extra_id   :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
