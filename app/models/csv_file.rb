class CsvFile < ActiveRecord::Base

  belongs_to :entity, :polymorphic => true
  before_destroy :remove_csv_file

  attr_accessible :entity

  def location
    "#{Rails.root}/#{read_attribute(:location)}"
  end

  private
  def remove_csv_file
    if File.exist?(location)
      FileUtils.rm(location)
    end
  end
end

# == Schema Information
#
# Table name: csv_files
#
#  id          :integer          not null, primary key
#  name        :string(255)
#  location    :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  entity_type :string(255)
#  entity_id   :integer
#
