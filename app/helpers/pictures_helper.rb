module PicturesHelper

  def picture_id(picture)
    picture.label_from_filename.gsub(/ /,'').gsub(/\./, "_")
  end
  
end
