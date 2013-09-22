class Avatar < ActiveRecord::Base  
  IMG_SIZE = '"600x600>"'
  THUMB_SIZE = '"200x200>"'
  SMALL_SIZE = '"100x100>"'
  TINY_SIZE = '"50x50>"'

  if ENV["RAILS_ENV"] == "test"
    URL_STUB = DIRECTORY = "tmp"
  else
    URL_STUB = "/images/avatars"
    DIRECTORY = File.join("public", "images", "avatars")
  end
  
  def initialize(user, image = nil)
    @user = user
    @image = image
    Dir.mkdir(DIRECTORY) unless File.directory?(DIRECTORY)
  end
  
  def exists?
    File.exists?(File.join(DIRECTORY, filename))
  end

  def exist?
    exists?
  end
  
  def url
    if exists?
      "#{URL_STUB}/#{filename}"
    else
      "/images/n_silhouette.gif"
    end
  end
  
  def thumbnail_url
    if exists?
      "#{URL_STUB}/#{thumbnail_name}"
    else
      "/images/n_silhouette.gif"
    end
  end
  
  def small_url
    if exists?
      "#{URL_STUB}/#{small_name}"
    else
      "/images/s_silhouette.jpg"
    end
  end
  
  def tiny_url
    if exists?
      "#{URL_STUB}/#{tiny_name}"
    else
      "/images/t_silhouette.gif"
    end
  end
  
  def default_icon_url
    "/images/default_icon.gif"
  end
  
  def save
    valid_file? and successful_conversion?
  end
  
  def delete
    [filename, thumbnail_name, small_name, tiny_name].each do |name|
      image = "#{DIRECTORY}/#{name}"
      File.delete(image) if File.exists?(image)
    end
  end

  private

  def filename
    "#{@user.username}_n.png"
  end  

  def thumbnail_name
    "#{@user.username}_q.png"
  end
  
  def small_name
    "#{@user.username}_s.png"
  end
  
  def tiny_name
    "#{@user.username}_t.png"
  end

  def convert
    if ENV["OS"] =~ /Windows/
      "C:\\Program Files\\ImageMagick-6.3.1-Q16\\convert"
    else
      "/usr/bin/convert"
    end
  end
  
  def successful_conversion?
    source = File.join("tmp", "#{@user.username}_full_size")
    full_size = File.join(DIRECTORY, filename)
    thumbnail = File.join(DIRECTORY, thumbnail_name)
    small = File.join(DIRECTORY, small_name)
    tiny = File.join(DIRECTORY, tiny_name)
    File.open(source, "wb") { |f| f.write(@image.read) }
    img   = system("#{convert} #{source} -resize #{IMG_SIZE} #{full_size}")
    thumb = system("#{convert} #{source} -resize #{THUMB_SIZE} #{thumbnail}")
    small = system("#{convert} #{source} -resize #{SMALL_SIZE} #{small}")
    tiny = system("#{convert} #{source} -resize #{TINY_SIZE} #{tiny}")
    File.delete(source) if File.exists?(source)
    unless img and thumb and small and tiny
      errors.add_to_base("抱歉！檔案上傳失敗，請嘗試其他的圖檔")
      return false
    end
    return true
  end
  
  def valid_file?
    if @image.size.zero?
      errors.add_to_base("請為你的照片輸入檔案名稱")
      return false
    end   
    unless @image.content_type =~ /^image/
      errors.add(:image, "並不是合法的圖片格式")
      return false
    end
    if @image.size > 2.megabyte
      errors.add(:image, "檔案大小上限為 2MB，請嘗試較小的圖檔")
      return false    
    end
    return true
  end
end