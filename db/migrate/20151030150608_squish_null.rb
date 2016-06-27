class SquishNull < ActiveRecord::Migration
  def up
    execute function_sql('20151030150608', 'squish_null')
  end

  def down
    execute 'DROP FUNCTION squish_null;'
    execute 'DROP FUNCTION squish;'
  end
end
