class DropUserSectionSubmissionStatesLoop < ActiveRecord::Migration
  def self.up
    execute 'DROP TABLE IF EXISTS user_section_submission_states_loop'
  end

  def self.down
  end
end
