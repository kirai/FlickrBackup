require 'debugger'
require_relative 'startup_settings.rb'

class PhotoFetcher

  def download_photoset(photoset_id, local_photoset_folder_path, post_to_glacier=false)
    hydra = Typhoeus::Hydra.new(:max_concurrency => 20)
    glacier_connector = GlacierConnector.new(get_glacier_credentials)

    flickr.photosets.getPhotos(:photoset_id => photoset_id).photo.each do |photo|

      photo_info = flickr.photos.getInfo(:photo_id => photo.id)
      url = FlickRaw.url_o(photo_info) rescue FlickRaw.url_m(photo_info) rescue ''
      filename = CGI.unescapeHTML(photo.title).gsub(/ |&|,|-/, '_').gsub(/'/, '').downcase.squeeze('_') + '_' + photo.id + '.jpg'
      file_path = local_photoset_folder_path + filename

      if (!post_to_glacier && File.exists?(file_path))
        #Checking if a file exists on Glacier is sloooow
        puts "Duplicada"
      else
        puts "Encolando fotaco en la hydra"
        r = Typhoeus::Request.new(url)
        r.on_complete do |response|
          post_to_glacier ? glacier_connector.freeze(filename, response.body) : store_local(filename, response.body, file_path, photo_info)
        end
        hydra.queue r
      end
      if hydra.queued_requests.size > TASA_DE_SULFATAMIENTO
         puts "La hydra se pone a currar"
         hydra.run
      end
      sleep(1)  # Para no sulfatar el API de flickr
    end
  end

  def store_local(filename, file, file_path, photo_info)
    #Save file at local path
    open("#{file_path}", "wb"){|f| f.write(file)}
    #Edit exif information
    tags = ExifHelper::flickr_tags_to_string(photo_info.tags.to_a)
    ExifHelper::edit_tags(tags, file_path)
  end

end
