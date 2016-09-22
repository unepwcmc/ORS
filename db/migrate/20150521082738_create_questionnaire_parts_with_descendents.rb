class CreateQuestionnairePartsWithDescendents < ActiveRecord::Migration
  def up
    execute function_sql('20150521082738', 'questionnaire_parts_with_descendents')
  end

  def down
  end
end
