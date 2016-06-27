class DelegateTextAnswer < ActiveRecord::Base

  attr_accessible :answer_id, :user_id, :answer_text, :created_at, :updated_at

  belongs_to :answer
  belongs_to :user

  validates_uniqueness_of :user_id, :scope => :answer_id

end
