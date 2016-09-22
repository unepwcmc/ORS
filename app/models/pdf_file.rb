class PdfFile < ActiveRecord::Base

  attr_accessible :questionnaire, :user, :is_long

  belongs_to :user
  belongs_to :questionnaire

  before_destroy :remove_pdf_file

  def location
    "#{Rails.root}/#{read_attribute(:location)}"
  end

  private
  def remove_pdf_file
    if File.exist?(location)
      FileUtils.rm(location)
    end
  end
end

# == Schema Information
#
# Table name: pdf_files
#
#  id               :integer          not null, primary key
#  questionnaire_id :integer          not null
#  user_id          :integer          not null
#  name             :string(255)
#  location         :string(255)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  is_long          :boolean          default(TRUE)
#
