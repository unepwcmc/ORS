class SectionField < ActiveRecord::Base
  attr_accessible :language, :is_default_language, :tab_title, :title,
    :description

  ###
  ###   Include Libs
  ###
  include LanguageMethods

  ###
  ###   Relationships
  ###
  belongs_to :section

  ###
  ###   Validations
  ###
  validates_uniqueness_of :language, :scope => :section_id #a section field of each language per section
  #validates_presence_of :title

end

# == Schema Information
#
# Table name: section_fields
#
#  id                  :integer          not null, primary key
#  title               :text
#  language            :string(255)      not null
#  description         :text
#  section_id          :integer          not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  is_default_language :boolean          default(FALSE), not null
#  tab_title           :text
#
