require 'cgi'
require 'flickraw'
require 'net/http'
require 'uri'
require 'yaml'
require 'logger'
require 'typhoeus'
require 'commander/import'
require_relative 'lib/flickr_connector.rb'

################################################################################
program :name, 'Ruby Flickr Backup'
program :version, '0.0.1'
program :description, 'Ruby Flickr script to download full sized pictures from 
                       your flickr photostream'

command :photoset do |c|
  c.syntax = 'flickr_backup.rb photoset [options]'
  c.description = 'Downloads all the pictures from a specific photoset'
  c.option '--photosetid PhotosetId', String, 'Photoset id to be downloaded'
  c.action do |args, options|
    #if options.default[:photosetid]
    #  photoset_id = options.default[:photosetid]
    #end
    options.default :prefix => '(', :suffix => ')'
    say "#{options.prefix}#{options.suffix}"
  end
end

################################################################################

TASA_DE_SULFATAMIENTO = 5

photoset_id = '72157613159816302'

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

# Con Threads
#flickr.photosets.getList(:user_id => myUserId).each do |photo|
#
#  print "Threads activos: "
#  print threads.length
#
#  if threads.length > TASA_DE_SULFATAMIENTO 
#    threads.each do |t|
#      t.join
#    end
#    threads.clear
#  end
#
#  begin
#
#    url = flickr.photos.getSizes(:photo_id => photo.primary).find{|p| p["label"]=="Original"}["source"] rescue ''
#    filename = CGI.unescapeHTML(photo.title).gsub(/ |&|,|-/, '_').gsub(/'/, '').downcase.squeeze('_') + '_' + photo.primary + '.jpg'
#    filepath = LOCAL_PHOTO_DIR + filename
#
#    if File.exists?(filepath)
#      puts "Duplicada"
#    else
#      puts "Pillando fotaco"
#      threads << Thread.new {
#        uri = URI(url)
#        Net::HTTP.start(uri.host) do |http|
#          resp = http.get(uri.path)
#          open("#{filepath}", "wb") do |file|
#            file.write(resp.body)
#          end
#        end
#      }
#    end
#
#  rescue Exception => e
#    "Algo ha petado mientras trataba de pillar una foto"
#  end
#  puts "\n"
#end
