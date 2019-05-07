class Document < ActiveRecord::Base

  attr_protected :doc_file_name, :doc_content_type, :doc_file_size

  ###
  ###   Relationships
  ###
  belongs_to :answer
  has_one :user, :through => :answer
  has_one :questionnaire, :through => :answer
  belongs_to :original, :class_name => 'Document',
    :foreign_key => :original_id
  has_many :copies, :class_name => 'Document',
    :foreign_key => :original_id, :dependent => :nullify

  ###
  ###   Paperclip Initializations
  ###
  has_attached_file :doc,
                    :url =>  "#{ActionController::Base.relative_url_root}/answers/:answer_id/documents/:id",
                    :path => ":rails_root/private/answer_docs/:questionnaire_id/answer_documents/:user_id/:id/:basename.:extension" #:id_partition

  validates_attachment_presence :doc
  validates_attachment_size :doc, :less_than => 10.megabytes
  do_not_validate_attachment_file_type :doc
end

# == Schema Information
#
# Table name: documents
#
#  id               :integer          not null, primary key
#  answer_id        :integer          not null
#  doc_file_name    :text             not null
#  doc_content_type :string(255)
#  doc_file_size    :integer
#  doc_updated_at   :datetime
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  description      :text
#  original_id      :integer
#
