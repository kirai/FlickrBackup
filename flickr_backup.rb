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
require_relative 'lib/photo_fetcher.rb'
require_relative 'lib/glacier_connector.rb'
require_relative 'lib/storage.rb'

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

# Storage type
if use_glacier
  storage = Storage.create :StorageGlacier
else
  storage = Storage.create :StorageLocal
end

# Starting the download process with typhoeus, hydras y toa la pesca
print "Downloading ", flickrUserName, "'s photos \n"
print "From photoset: ", photoset_name, "\n"
print "Store in glacier? ", use_glacier, "\n"

photo_fetcher = PhotoFetcher.new
photo_fetcher.download_photoset(photoset_id, local_photoset_folder_path, use_glacier, storage)

