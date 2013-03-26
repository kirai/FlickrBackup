require 'cgi'
require 'flickraw'
require 'net/http'
require 'uri'
require 'yaml'
require 'logger'
require 'typhoeus'
require 'optparse'
require 'ftools'
require_relative 'lib/flickr_connector.rb'
require_relative 'lib/startup_settings.rb'

TASA_DE_SULFATAMIENTO = 5
local_photo_dir = '~/Desktop/'

log = Logger.new( 'log.txt', 'daily' )
log.info("Starting...")

options = parse_options
photoset_id = options[:photosetid]
use_glacier = options[:glacier]

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
print "Store in glacier? ", glacier, "\n"

hydra = Typhoeus::Hydra.new(:max_concurrency => 20)

flickr.photosets.getPhotos(:photoset_id => photoset_id).photo.each do |photo|
  url = flickr.photos.getSizes(:photo_id => photo.id).find{|p| p["label"]=="Original"}["source"] rescue ''
  filename = CGI.unescapeHTML(photo.title).gsub(/ |&|,|-/, '_').gsub(/'/, '').downcase.squeeze('_') + '_' + photo.id + '.jpg'
  filepath = local_photoset_folder_path + filename

  if File.exists?(filepath)
    puts "Duplicada"
  else
    puts "Encolando fotaco en la hydra"
    r = Typhoeus::Request.new(url)
    r.on_complete do |response|
      open("#{filepath}", "wb") do |file|
        file.write(response.body)
      end
    end
    hydra.queue r
  end

  if hydra.queued_requests.size > TASA_DE_SULFATAMIENTO
     puts "La hydra se pone a currar"
     hydra.run
  end
  sleep(1)  # Para no sulfatar el API de flickr
end
