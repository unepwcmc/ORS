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

  attr_accessible :title, :title_en, :title_fr, :title_es,
    :short_title, :short_title_en, :short_title_fr, :short_title_es,
    :sub_title, :sub_title_en, :sub_title_fr, :sub_title_es,
    :logo, :logo_url, :show_sign_up
  translates :title, :short_title, :sub_title
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

  # Since the pivot tables output is a specialised one created for Ramsar,
  # with requirements on data presence and structure unlikely to be found
  # elsewhere, enable this only for the Ramsar instance.
  def self.pivot_tables_download_enabled?
    !!(title =~ /ramsar/i) ||
    !!(short_title =~ /ramsar/i) ||
    !!(sub_title =~ /ramsar/i)
  end
end
