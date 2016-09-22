class SourceFile < ActiveRecord::Base

  extend EnumerateIt
  has_enumeration_for :parse_status, :with => ParseFileStatus, :create_helpers => true

  belongs_to :loop_source
  has_many :persistent_errors, :as => :errorable, :dependent => :destroy

  ###
  ###		Paperclip Initializations
  ###
  has_attached_file :source
  #validates_attachment_content_type :source, :content_type => ["text/plain", "text/csv"]
  do_not_validate_attachment_file_type :source

  attr_accessible :source

  def <=>(source_file)
    created_at <=> source_file.created_at
  end
end

# == Schema Information
#
# Table name: source_files
#
#  id                  :integer          not null, primary key
#  loop_source_id      :integer          not null
#  source_file_name    :text             not null
#  source_content_type :string(255)
#  source_file_size    :integer
#  source_updated_at   :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  parse_status        :integer          default(0)
#
