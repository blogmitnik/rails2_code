module PhotosHelper
  include ActionView::Helpers::AssetTagHelper
  
  def photo_id(photo)
    photo.label_from_filename.gsub(/ /,'').gsub(/\./, "_")
  end
  
  def image photo, size = :thumb, img_opts = {}
    return image_tag(image_path( photo, size), :class => size) if photo.filename.blank?
    img_tag = image_tag(photo_path( photo, size), {:title=>photo.title, :alt=>photo.title, :class=>size}.merge(img_opts))
    img_tag
  end
  
  def photo_path photo = nil, size = :thumb
    path = nil
    unless photo.nil? || photo.filename.blank?
      path = url_for_file_column(photo, :filename, size.to_s) rescue nil
    end
    path = missing_photo_path(size) if path.nil?
    return path
  end
  
  def allowed_photo_sizes
    [:avatar, :thumb, :small, :tiny, :icon, :bounded_icon]
  end
  
  def missing_photo_path(size)
    if allowed_photo_sizes.include?(size)
      "/images/missing_#{size}.png"
    else
      '/images/missing.png'
    end
  end
  
  def image_path_with_photo(source_or_photo, size = :thumb)
    source_or_photo.respond_to?(:filename) ? photo_path(source_or_photo, size) : image_path_without_photo(source_or_photo)
  end
  alias_method_chain :image_path, :photo
end
