class CreateDelegateTextAnswerModel < ActiveRecord::Migration
  def up
    create_table "delegate_text_answers" do |t|
      t.integer  "answer_id"
      t.integer  "user_id"
      t.text     "answer_text"
      t.datetime "created_at",                   :null => false
      t.datetime "updated_at",                   :null => false
    end

    add_foreign_key(:delegate_text_answers, :answers, column: 'answer_id')
    add_foreign_key(:delegate_text_answers, :users, column: 'user_id')
  end

  def down
    drop_table "delegate_text_answers" if ActiveRecord::Base.connection.table_exists? "delegate_text_answers"
  end
end
