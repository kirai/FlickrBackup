# Ruby Flickr Backup 0.1

A Ruby script to download Flickr photosets pictures (Original resolution)

## Installation and setup

bundle install

Need to edit the settings.yaml file in the same folder with this fields:

```
flickr:
  api_key: YOUR_FLICKR_API_KEY
  shared_secret: YOUR_SHARED_SECRET
  access_token: YOUR_ACCESS_TOKEN
  access_secret: YOUR_FLICKR_ACCESS_SECRET
  flickr_user_name: YOUR_USER_NAME
local:
  photo_folder: /Users/hector-garcia/Desktop/
```

## Usage

ruby flickr_backup.rb --photosetid=72157613159816302

## Copyright

Feel free to do whatever you want with this code
