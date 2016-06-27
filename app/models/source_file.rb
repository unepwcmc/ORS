class SourceFile < ActiveRecord::Base

  extend EnumerateIt
  has_enumeration_for :parse_status, :with => ParseFileStatus, :create_helpers => true

  belongs_to :loop_source
  has_many :persistent_errors, :as => :errorable, :dependent => :destroy

  ###
  ###		Paperclip Initializations
  ###
  has_attached_file :source
  validates_attachment_content_type :source, :content_type => ["text/plain", "text/csv"]

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
#  loop_source_id      :integer
#  source_file_name    :string(255)
#  source_content_type :string(255)
#  source_file_size    :integer
#  source_updated_at   :datetime
#  created_at          :datetime
#  updated_at          :datetime
#  parse_status        :integer          default(0)
#
