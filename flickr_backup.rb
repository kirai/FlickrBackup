require 'cgi'
require 'flickraw'
require 'net/http'
require 'uri'
require 'yaml'
require 'logger'
require 'typhoeus'
require 'optparse'
require 'ftools'
require 'mini_exiftool'
require_relative 'lib/flickr_connector.rb'
require_relative 'lib/startup_settings.rb'
require_relative 'lib/exif_helper.rb'

TASA_DE_SULFATAMIENTO = 5
local_photo_dir = '~/Desktop/'

log = Logger.new( 'log.txt', 'daily' )
log.info("Starting...")

photoset_id = parse_options
settings = parse_yaml

#Flickr API connection
flickr_connector = FlickrConnector.new

flickr_connector.set_api_key_shared_secret( settings["flickr"]["api_key"],
                                            settings["flickr"]["shared_secret"])

if (!settings["flickr"]["access_token"] || !settings["flickr"]["access_secret"])
  flickr_connector.request_token
end

# Flickr info
flickr.access_token = settings["flickr"]["access_token"]
flickr.access_secret = settings["flickr"]["access_secret"]
flickrUserName = settings["flickr"]["flickr_user_name"]
myUserId = flickr.people.findByUsername(:username => flickrUserName).id
photoset_name = flickr.photosets.getInfo(:photoset_id => photoset_id).title

# Local path to store the picture
(local_photo_dir = settings["local"]["photo_folder"]) if settings["local"]["photo_folder"]
local_photoset_folder_path = local_photo_dir + photoset_name + '/'
FileUtils.mkdir_p(local_photoset_folder_path) unless File.exists?(local_photoset_folder_path)

# Starting the download process with typhoeus, hydras y toa la pesca
print "Downloading ", flickrUserName, "'s photos \n"
print "From photoset: ", photoset_name, "\n"

hydra = Typhoeus::Hydra.new(:max_concurrency => 20)

flickr.photosets.getPhotos(:photoset_id => photoset_id).photo.each do |photo|
  
  photo_info = flickr.photos.getInfo(:photo_id => photo.id)
  
  url = FlickRaw.url_o(photo_info) rescue FlickRaw.url_m(photo_info) rescue '' 
  filename = CGI.unescapeHTML(photo.title).gsub(/ |&|,|-/, '_').gsub(/'/, '').downcase.squeeze('_') + '_' + photo.id + '.jpg'
  filepath = local_photoset_folder_path + filename


  if File.exists?(filepath)
    puts "Duplicada"
  else
    puts "Encolando fotaco en la hydra"
    r = Typhoeus::Request.new(url)
    r.on_complete do |response|
      
      #Save file at local path
      open("#{filepath}", "wb") do |file|
        file.write(response.body)
      end
     
      #Edit exif information
      tags = ExifHelper::flickr_tags_to_string(photo_info.tags.to_a)
      ExifHelper::edit_tags(tags, filepath)

    end
    hydra.queue r
  end

  if hydra.queued_requests.size > TASA_DE_SULFATAMIENTO
     puts "La hydra se pone a currar"
     hydra.run
  end
  sleep(1)  # Para no sulfatar el API de flickr
end
