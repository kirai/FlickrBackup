# coding: utf-8
require_relative '../lib/exif_helper.rb'

describe ExifHelper do
  
  it "should stringify flickr_raw tags information" do
    tags = [{"id"=>"256435-8561313944-457809", "author"=>"69078600@N00", "raw"=>"nezu", "_content"=>"nezu", "machine_tag"=>0}, {"id"=>"256435-8561313944-21775", "author"=>"69078600@N00", "raw"=>"neko", "_content"=>"neko", "machine_tag"=>0}, {"id"=>"256435-8561313944-13756", "author"=>"69078600@N00", "raw"=>"gato", "_content"=>"gato", "machine_tag"=>0}, {"id"=>"256435-8561313944-209663", "author"=>"69078600@N00", "raw"=>"neco", "_content"=>"neco", "machine_tag"=>0}, {"id"=>"256435-8561313944-1344", "author"=>"69078600@N00", "raw"=>"cat", "_content"=>"cat", "machine_tag"=>0}, {"id"=>"256435-8561313944-36478", "author"=>"69078600@N00", "raw"=>"猫", "_content"=>"猫", "machine_tag"=>0}]

    stringified_tags = ExifHelper::flickr_tags_to_string(tags)
    stringified_tags.should eq("nezu, neko, gato, neco, cat, 猫") 
  end

  it "should return an empty string if the picture doesn't have any tags" do
    tags = []
    stringified_tags = ExifHelper::flickr_tags_to_string(tags)
    stringified_tags.should eq("") 
  end

end
