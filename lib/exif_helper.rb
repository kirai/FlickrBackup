require 'mini_exiftool'

class ExifHelper


  # Use this to transform an array of tags from a FlickRaw::ResponseList to a string
  # of comma separated tags
  #
  #  string_of_tags = ExifHelper::flickr_tags_to_string(photo_info.tags.to_a)
  #

  def self.flickr_tags_to_string(tags)
    tags_string = ""
    tags.each { |tag| tag != tags.last ? tags_string << (tag["raw"] + ', ') : tags_string << tag["raw"] } unless tags.empty?
    return tags_string
  end

  # Use this to edit the exif information of an image
  # TODO: comment? see where the tags are saved by software like Lightroom

  def self.edit_tags(tags, filepath)
    photo_exif = MiniExiftool.new(filepath)
    photo_exif.comment = tags 
    photo_exif.save
  end
end
