class ApplicationProfile < ActiveRecord::Base

  attr_accessible :title, :short_title, :logo, :logo_url

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

end
