class FlickrConnector

  def set_api_key_shared_secret(api_key, shared_secret)
    FlickRaw.api_key  = api_key
    FlickRaw.shared_secret = shared_secret
  end
  
  def request_token
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

end

