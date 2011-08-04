Summary

   GridAttachment is a GridFS plugin for MongoDB ORMs.
   Supports MongoMapper, Mongoid, MongoODM, and Mongomatic.

   Support is built in for rack_grid and rack_grid_thumb to generate URLS and thumbnails:
     http://github.com/dusty/rack_grid
     http://github.com/dusty/rack_grid_thumb

   You can pass in a File or a Hash as received by Sinatra on file uploads.

Installation

  # gem install grid_attachment

Usage

  require 'grid_attachment/mongo_mapper'
  class Monkey
    include MongoMapper::Document
    plugin GridAttachment::MongoMapper

    attachment :image, :prefix => :grid
  end

  require 'grid_attachment/mongo_odm'
  class Monkey
    include MongoODM::Document
    include GridAttachment::MongoODM

    attachment :image, :prefix => :grid
  end

  require 'grid_attachment/mongomatic'
  class Monkey < Mongomatic::Base
    include GridAttachment::Mongomatic

    attachment :image, :prefix => :grid
  end

  require 'grid_attachment/mongoid'
  class Monkey
    include Mongoid::Document
    include GridAttachment::Mongoid

    attachment :image, :prefix => :grid
  end

  m = Monkey.new(:name => 'name')
  m.save

  # To add an attachment from the filesystem
  m.image = File.open('/tmp/me.jpg')
  m.save

  # To remove an attachment
  m.image = nil
  m.save

  # To get the attachment
  m.image.read

  # To get the URL for rack_grid
  m.image_url                          # /grid/4e049e7c69c3b27d53000005/me.jpg

  # To get the thumbail URL for rack_grid_thumb
  m.image_thumb('50x50')               # /grid/4e049e7c69c3b27d53000005/me_50x50.jpg

  # HTML form example
  <form action = "/monkeys" method="post" enctype="multipart/form-data">
    <input id="image" name="image" type="file" />
  </form>

  # Use the image hash provided in params with Sinatra
  post '/monkeys' do
    m = Monkey.new
    m.image = params[:image]
    m.save
    # Or just Monkey.new(params).save
  end


Inspired By
  - http://github.com/jnunemaker/joint

