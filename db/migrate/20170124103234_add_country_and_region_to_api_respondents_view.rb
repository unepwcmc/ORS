class AddCountryAndRegionToApiRespondentsView < ActiveRecord::Migration
  def up   
    execute 'DROP VIEW IF EXISTS api_respondents_view'
    execute view_sql('20170124103234', 'api_respondents_view')
  end

  def down
    execute 'DROP VIEW IF EXISTS api_respondents_view'
    execute view_sql('20151030151237', 'api_respondents_view')
  end
end
