Summary

   GridAttachment is a GridFS plugin for MongoDB ORMs.
   Supports MongoMapper, Mongoid, MongoODM, and Mongomatic.

   Support is built in for rack/gridfs.  Can also be used with rack/thumb to dynamically
   generate thumbnails, and rack/cache to cache files.

     Rack::Gridfs - https://github.com/skinandbones/rack-gridfs.git
     Rack::Thumb  - https://github.com/akdubya/rack-thumb
     Rack::Cache  - https://github.com/rtomayko/rack-cache

Installation

  # gem install grid_attachment

Usage

  # To use with rack/gridfs you will need to define a custom mapper.
  # For example, with Sinatra.

  use Rack::Cache, {
    :verbose     => false,
    :metastore   => 'file:/var/cache/rack/meta',
    :entitystore => 'file:/var/cache/rack/body'
  }

  use Rack::Thumb

  # Custom mapper allows rack/gridfs to use the URL schema provided by grid_attachment.
  use Rack::GridFS, {
    :prefix => 'grid',
    :db => MongoMapper.database,
    :expires => 1800,
    :mapper => lambda { |path| %r{^/grid/(\w+)/.*}.match(path)[1] }
  }

  # Define your models depending on the ORM you use.

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

  # To get the URL for rack/gridfs
  m.image_url                          # /grid/4e049e7c69c3b27d53000005/me.jpg

  # To get the thumbail URL for rack/thumb
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

