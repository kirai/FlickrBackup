#require 'debugger'
require_relative 'startup_settings.rb'

class PhotoFetcher

  def download_photoset(photoset_id, local_photoset_folder_path, post_to_glacier=false, storage)

    hydra = Typhoeus::Hydra.new(:max_concurrency => 20)

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
          post_to_glacier ? storage.save(filename, response.body) : storage.save(filename, response.body, file_path, photo_info) # TODO: get rid of this conditional
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
end
