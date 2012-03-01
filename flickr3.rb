require 'cgi'
require 'flickraw-cached'
require 'flickraw'
require 'net/http'
require 'uri'
require 'yaml'
require 'logger'

log = Logger.new( 'log.txt', 'daily' )

log.info("Starting...")

def requestToken
  token = flickr.get_request_token
  auth_url = flickr.get_authorize_url(token['oauth_token'], :perms => 'delete')

  puts "Open this url: #{auth_url}"
  puts "Copy here the number given when you complete the process."
  verify = gets.strip

  begin
    flickr.get_access_token(token['oauth_token'], token['oauth_token_secret'], verify)
    login = flickr.test.login
    puts "You are now authenticated as #{login.username} with token #{flickr.access_token} and secret #{flickr.access_secret}"
    puts "Complete the settings.yaml file with your login information"
  rescue FlickRaw::FailedResponse => e
    puts "Authentication failed : #{e.msg}"
  end
  exit
end

begin
  settings = YAML::load_file('settings.yaml')
rescue ArgumentError => e
  puts "Could not parse YAML: #{e.message}"
end

if (!settings["flickr"]["api_key"] || !settings["flickr"]["shared_secret"] || !settings["flickr"]["access_token"] || !settings["flickr"]["access_secret"])
  requestToken
end

FlickRaw.api_key  = settings["flickr"]["api_key"]
FlickRaw.shared_secret = settings["flickr"]["shared_secret"]
flickr.access_token = settings["flickr"]["access_token"]
flickr.access_secret = settings["flickr"]["access_secret"]

flickrUserName = settings["flickr"]["flickr_user_name"]
LOCAL_PHOTO_DIR = '/Users/hector-garcia/Desktop/'

myUserId = flickr.people.findByUsername(:username => flickrUserName).id
threads = Array.new

print "Downloading ", flickrUserName, "'s photos \n"

flickr.photosets.getList(:user_id => myUserId).each do |photo|

  print "Threads activos: "
  print threads.length

  if threads.length > 5
    threads.each do |t|
      t.join
    end
    threads.clear
  end

  begin

    url = flickr.photos.getSizes(:photo_id => photo.primary).find{|p| p["label"]=="Original"}["source"] rescue ''
    filename = CGI.unescapeHTML(photo.title).gsub(/ |&|,|-/, '_').gsub(/'/, '').downcase.squeeze('_') + '_' + photo.primary + '.jpg'
    filepath = LOCAL_PHOTO_DIR + filename

    if File.exists?(filepath)
      puts "Duplicada"
    else
      puts "Pillando fotaco"
      threads << Thread.new {
        uri = URI(url)
        Net::HTTP.start(uri.host) do |http|
          resp = http.get(uri.path)
          open("#{filepath}", "wb") do |file|
            file.write(resp.body)
          end
        end
      }
    end

  rescue Exception => e
    "Algo ha petado mientras trataba de pillar una foto"
  end
  puts "\n"
end
