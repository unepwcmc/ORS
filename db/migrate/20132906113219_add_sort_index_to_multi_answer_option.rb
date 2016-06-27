class AddSortIndexToMultiAnswerOption < ActiveRecord::Migration
  def self.up
    unless column_exists?(:multi_answer_options, :sort_index)
      add_column :multi_answer_options, :sort_index, :integer
    end
  end

  def self.down
    if column_exists?(:multi_answer_options, :sort_index)
      remove_column :multi_answer_options, :sort_index
    end
  end
end
