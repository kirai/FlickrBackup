require 'cgi'
require 'flickraw'
require 'net/http'
require 'uri'
require 'yaml'
require 'logger'
require 'typhoeus'
require 'optparse'
require_relative 'lib/flickr_connector.rb'

hash_options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: your_app [options]"
  opts.on('-p [ARG]', '--photosetid [ARG]', "Specify the photosetid") do |v|
    hash_options[:photosetid] = v
  end
  opts.on('--version', 'Display the version') do 
    puts "Ruby Flickr Backup 0.1"
    exit
  end
  opts.on('-h', '--help', 'Display this help') do 
    puts opts
    exit
  end
end.parse!

if !hash_options[:photosetid]
  puts 'Usage:'
  puts 'ruby flickr_backup.rb --photosetid [your flickr photosetid]'
  exit
else
  photoset_id = hash_options[:photosetid]
end

TASA_DE_SULFATAMIENTO = 5

#photoset_id = '72157613159816302'

log = Logger.new( 'log.txt', 'daily' )

log.info("Starting...")

begin
  settings = YAML::load_file('settings.yaml')
rescue Exception => e
  puts "Could not parse YAML: #{e.message}"
  exit
end

if (!settings["flickr"]["api_key"] || !settings["flickr"]["shared_secret"] )
  puts "Add your API KEY and Shared Secret to the settings.yaml file"
  exit
end

flickr_connector = FlickrConnector.new
flickr_connector.set_api_key_shared_secret( settings["flickr"]["api_key"],
                                            settings["flickr"]["shared_secret"])

if (!settings["flickr"]["access_token"] || !settings["flickr"]["access_secret"])
  flickr_connector.request_token
end

flickr.access_token = settings["flickr"]["access_token"]
flickr.access_secret = settings["flickr"]["access_secret"]
flickrUserName = settings["flickr"]["flickr_user_name"]

if(!settings["local"]["photo_folder"])
  LOCAL_PHOTO_DIR = '~/Desktop/'
else
  LOCAL_PHOTO_DIR = settings["local"]["photo_folder"]
end

myUserId = flickr.people.findByUsername(:username => flickrUserName).id
threads = Array.new

print "Downloading ", flickrUserName, "'s photos \n"

#Con typhoeus, hydras y toa la pesca

hydra = Typhoeus::Hydra.new(:max_concurrency => 20)

flickr.photosets.getList(:user_id => myUserId).each do |photo|

  url = flickr.photos.getSizes(:photo_id => photo.primary).find{|p| p["label"]=="Original"}["source"] rescue ''
  filename = CGI.unescapeHTML(photo.title).gsub(/ |&|,|-/, '_').gsub(/'/, '').downcase.squeeze('_') + '_' + photo.primary + '.jpg'
  filepath = LOCAL_PHOTO_DIR + filename

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
