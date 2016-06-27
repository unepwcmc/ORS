class StripTags < ActiveRecord::Migration
  def up
    execute function_sql('20151029095232', 'strip_tags')
  end

  def down
    execute 'DROP FUNCTION strip_tags;'
  end
end
