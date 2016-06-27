class AddQuestionAnsweredFieldToAnswers < ActiveRecord::Migration
  def up
    add_column :answers, :question_answered, :boolean, default: false
  end

  def down
    remove_column :answers, :question_answered
  end
end
