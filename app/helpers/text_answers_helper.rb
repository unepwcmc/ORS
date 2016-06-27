module TextAnswersHelper
  #returns the text_answer_field_fields object with language :language
  # or builds a new object with :language if it doesn't exist
  def get_text_answer_field_object f, language
    ( f.object.text_answer_field_fields.find_by_language(language) || f.object.text_answer_field_fields.build(:language => language) )
  end
end
