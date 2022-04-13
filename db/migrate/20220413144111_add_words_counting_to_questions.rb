class AddWordsCountingToQuestions < ActiveRecord::Migration
  def change
    add_column :questions, :allow_words_counting, :boolean, default: false
  end
end
