class AddAnswerTextInEnglishAndOriginalLanguageToAnswerParts < ActiveRecord::Migration
  def self.up
    unless column_exists?(:answer_parts, :answer_text_in_english)
      add_column :answer_parts, :answer_text_in_english, :text
    end
    unless column_exists?(:answer_parts, :original_language)
      add_column :answer_parts, :original_language, :string
    end
  end

  def self.down
    if column_exists?(:answer_parts, :answer_text_in_english)
      remove_column :answer_parts, :answer_text_in_english
    end
    if column_exists?(:answer_parts, :original_language)
      remove_column :answer_parts, :original_language
    end
  end
end
