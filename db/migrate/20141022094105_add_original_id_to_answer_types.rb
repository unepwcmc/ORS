class AddOriginalIdToAnswerTypes < ActiveRecord::Migration
  def self.up
    add_column :text_answers, :original_id, :integer
    add_foreign_key(:text_answers, :text_answers, {:column => :original_id, :dependent => :nullify})
    add_column :numeric_answers, :original_id, :integer
    add_foreign_key(:numeric_answers, :numeric_answers, {:column => :original_id, :dependent => :nullify})
    add_column :rank_answers, :original_id, :integer
    add_foreign_key(:rank_answers, :rank_answers, {:column => :original_id, :dependent => :nullify})
    add_column :range_answers, :original_id, :integer
    add_foreign_key(:range_answers, :range_answers, {:column => :original_id, :dependent => :nullify})
    add_column :multi_answers, :original_id, :integer
    add_foreign_key(:multi_answers, :multi_answers, {:column => :original_id, :dependent => :nullify})
    add_column :matrix_answers, :original_id, :integer
    add_foreign_key(:matrix_answers, :matrix_answers, {:column => :original_id, :dependent => :nullify})
    add_column :rank_answer_options, :original_id, :integer
    add_foreign_key(:rank_answer_options, :rank_answer_options, {:column => :original_id, :dependent => :nullify})
    add_column :range_answer_options, :original_id, :integer
    add_foreign_key(:range_answer_options, :range_answer_options, {:column => :original_id, :dependent => :nullify})
    add_column :multi_answer_options, :original_id, :integer
    add_foreign_key(:multi_answer_options, :multi_answer_options, {:column => :original_id, :dependent => :nullify})
    add_column :matrix_answer_options, :original_id, :integer
    add_foreign_key(:matrix_answer_options, :matrix_answer_options, {:column => :original_id, :dependent => :nullify})
    add_column :matrix_answer_drop_options, :original_id, :integer
    add_foreign_key(:matrix_answer_drop_options, :matrix_answer_drop_options, {:column => :original_id, :dependent => :nullify})
    add_column :matrix_answer_queries, :original_id, :integer
    add_foreign_key(:matrix_answer_queries, :matrix_answer_queries, {:column => :original_id, :dependent => :nullify})
  end

  def self.down
  end
end
