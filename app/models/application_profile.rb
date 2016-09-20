# == Schema Information
#
# Table name: application_profiles
#
#  id                :integer          not null, primary key
#  title             :string(255)      default("")
#  short_title       :string(255)      default("")
#  logo_url          :text             default("")
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  logo_file_name    :string(255)
#  logo_content_type :string(255)
#  logo_file_size    :integer
#  logo_updated_at   :datetime
#  sub_title         :string(255)      default("")
#

class ApplicationProfile < ActiveRecord::Base

  attr_accessible :title, :short_title, :sub_title, :logo, :logo_url, :show_sign_up

  # The # symbol after the size will scale and crop to exactly that size
  has_attached_file :logo, :styles => { :small => 'x55' }, :default_url => "/images/:style/missing.png"
  validates_attachment :logo, :size => { :in => 0..2.megabytes, :message => "The file's size must be less than 2MB"}
  validates_attachment_content_type :logo, :content_type => /\Aimage\/.*\Z/

  def self.title
    ApplicationProfile.first.try(:title).try(:presence) || "Online Reporting System"
  end

  def self.short_title
    ApplicationProfile.first.try(:short_title).try(:presence) || "ORS"
  end

  def self.sub_title
    ApplicationProfile.first.try(:sub_title).try(:presence) || ""
  end

  def self.logo_path
    ApplicationProfile.first.try(:logo).try(:url) || ""
  end

  def self.show_sign_up
    ApplicationProfile.first.try(:show_sign_up)
  end

end
