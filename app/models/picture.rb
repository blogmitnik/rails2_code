class Picture < ActiveRecord::Base
  validates_length_of :image, :within => 1024..256000
  validates_presence_of :name, :size, :image

  belongs_to :entry

  def file
  end
  
  def file=(file)
    write_attribute(:name, file.original_filename)
    write_attribute(:size, file.length)
    write_attribute(:image, file.read)
  end
end