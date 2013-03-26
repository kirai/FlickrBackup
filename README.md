# Ruby Flickr Backup 0.1

A Ruby script to download Flickr photosets pictures (Original resolution)

## Installation and setup

Step 1: bundle install

Step 2: Need to edit the settings.yaml file in the same folder with this fields:

```
flickr:
  api_key: YOUR_FLICKR_API_KEY
  shared_secret: YOUR_SHARED_SECRET
  access_token: YOUR_ACCESS_TOKEN
  access_secret: YOUR_FLICKR_ACCESS_SECRET
  flickr_user_name: YOUR_FLICKR_USER_NAME
local:
  photo_folder: /path/to/store/files/locally

#optional
aws:
  access_key: AWS_ACCESS_KEY
  secret_key: AWS_SECRET_KEY
  region: YOUR_AMAZON_REGION i.e us-west-1
  vault: YOUR_VAULT_NAME i.e myvault
```

## Usage
To store files locally use
ruby flickr_backup.rb --photosetid=72157613159816302

If you want to store your pictures on amazon glacier pass --glacier=Y option (ruby flickr_backup.rb --photosetid=72157613159816302 --glacer=Y)

## Copyright

Feel free to do whatever you want with this code
