class Storage

  def Storage.create subclass
    { :StorageLocal => StorageLocal, :StorageGlacier => StorageLocal }[subclass].new
  end

end

class StorageLocal < Storage

  def save(filename, file, file_path, photo_info)

    #Save the file
    open("#{file_path}", "wb"){|f| f.write(file)}
    
    #Save the tags inside the Exif header
    tags = ExifHelper::flickr_tags_to_string(photo_info.tags.to_a)
    ExifHelper::edit_tags(tags, file_path)
  end

end

class StorageGlacier < Storage

  def save(filename, response_body)
    glacier_connector = GlacierConnector.new(get_glacier_credentials)
    glacier_connector.freeze(filename, response_body) 
  end

end
