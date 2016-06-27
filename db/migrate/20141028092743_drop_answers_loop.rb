class DropAnswersLoop < ActiveRecord::Migration
  def self.up
    execute 'DROP TABLE IF EXISTS answers_loop'
  end

  def self.down
  end
end
