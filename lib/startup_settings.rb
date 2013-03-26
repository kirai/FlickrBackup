
def parse_options
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
  
  return photoset_id
end

def fetch_config
  begin
    YAML::load_file('settings.yaml')
  rescue Exception => e
    puts "Could not parse YAML: #{e.message}"
    exit
  end
end

def parse_yaml
  settings = fetch_config

  if (!settings["flickr"]["api_key"] || !settings["flickr"]["shared_secret"] )
    puts "Add your API KEY and Shared Secret to the settings.yaml file"
    exit
  end

  return settings
end

def get_glacier_credentials
  fetch_config['aws'] rescue puts 'There was an error fetching your Amazon Glacier configuration'
end