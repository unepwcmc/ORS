class AddOriginalIdToAnswers < ActiveRecord::Migration
  def self.up
    add_column :answers, :original_id, :integer
    add_foreign_key(:answers, :answers, {:column => :original_id, :dependent => :nullify})
    add_column :answer_parts, :original_id, :integer
    add_foreign_key(:answer_parts, :answer_parts, {:column => :original_id, :dependent => :nullify})
    add_column :text_answer_fields, :original_id, :integer
    add_foreign_key(:text_answer_fields, :text_answer_fields, {:column => :original_id, :dependent => :nullify})
  end

  def self.down
  end
end
