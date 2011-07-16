require 'mime/types'
require 'uri'

class GridmaticObserver < Mongomatic::Observer
  def after_insert_or_update(instance, opts)
    instance.send(:create_attachments)
    instance.send(:delete_attachments)
  end
  def before_remove(instance,opts)
    instance.send(:queue_delete_attachments)
    instance.send(:delete_attachments)
  end
end

module GridAttachment
  module Mongomatic

    def self.included(base)
      base.send(:include, Mongomatic::Observable)
      base.send(:observer, :GridmaticObserver)
      base.send(:include, InstanceMethods)
      base.send(:extend, ClassMethods)
    end

    module ClassMethods

      ##
      # Declare an attachment for the object
      #
      # eg: attachment :image
      def attachment(name,options={})
        prefix = options[:prefix] ||= :grid

        ##
        # Add this name to the attachment_types
        attachment_types.push(name).uniq!

        ##
        # Return the Grid object.
        # eg: image.filename, image.read
        define_method(name) do
          grid.get(self["#{name}_id"]) if self["#{name}_id"]
        end

        ##
        # Create a method to set the attachment
        # eg: object.image = File.open('/tmp/somefile.jpg')
        define_method("#{name}=") do |file|
          # delete the old file if it exists
          unless self["#{name}_id"].blank?
            send(:delete_attachment, name, self["#{name}_id"])
          end
          case
          when file.is_a?(Hash) && file[:tempfile]
            send(:create_attachment, name, file)
          when file.respond_to?(:read)
            send(:create_attachment, name, file)
          end
        end

        ##
        # Create a method to set the attachment for binary string.
        # eg: object.set_image(binary_string, "generated_filename.png")
        define_method("set_#{name}") do |binary, filename|
          if !binary.nil?
            send(:create_attachment_raw, name, binary, filename)
          else
            send(:delete_attachment, name, self["#{name}_id"])
          end
        end

        ##
        # Unset the attachment, queue for removal
        define_method("unset_#{name}") do
          send(:delete_attachment, name, self["#{name}_id"])
        end

        ##
        # Return the relative URL to the attachment for use with Rack::Grid
        # eg: /grid/4ba69fde8c8f369a6e000003/somefile.png
        define_method("#{name}_url") do
          _id   = self["#{name}_id"]
          _name = self["#{name}_name"]
          URI.escape(["/#{prefix}", _id, _name].join('/')) if _id && _name
        end

        ##
        # Return the relative URL to the thumbnail for use with Rack::GridThumb
        # eg: /grid/4ba69fde8c8f369a6e000003/somefile_50x.png
        define_method("#{name}_thumb") do |thumb|
          _id   = self["#{name}_id"]
          _name = self["#{name}_name"]
          _ext  = File.extname(_name)
          _base = File.basename(_name,_ext)
          _name = "#{_base}_#{thumb}#{_ext}"
          URI.escape(["/#{prefix}", _id, _name].join('/')) if _id && _name
        end
      end

      ##
      # Accessor to Grid
      def grid
        @grid ||= Mongo::Grid.new(::Mongomatic.db)
      end

      ##
      # All the attachments types for this class
      def attachment_types
        @attachment_types ||= []
      end

    end

    module InstanceMethods

      ##
      # Accessor to Grid
      def grid
        self.class.grid
      end

      private
      ##
      # Holds queue of attachments to create
      def create_attachment_queue
        @create_attachment_queue ||= {}
      end

      ##
      # Holds queue of attachments to delete
      def delete_attachment_queue
        @delete_attachment_queue ||= {}
      end

      ##
      # Attachments we need to add after save.
      def create_attachment(name,file)
        case
        when file.is_a?(Hash)
          filename = file[:filename]
          size     = File.size(file[:tempfile])
          mime     = file[:type]
          unless mime
            type = MIME::Types.type_for(filename).first
            mime = type ? type.content_type : "application/octet-stream"
          end
        when file.respond_to?(:read)
          filename = case
          when file.respond_to?(:original_filename) && file.original_filename
            file.original_filename
          when file.respond_to?(:tempfile)
            File.basename(file.tempfile.path)
          else
            File.basename(file.path)
          end
          size = File.size(file.respond_to?(:tempfile) ? file.tempfile : file)
          type = MIME::Types.type_for(filename).first
          mime = type ? type.content_type : "application/octet-stream"
        else
          return
        end
        self["#{name}_id"]   = BSON::ObjectId.new
        self["#{name}_name"] = filename
        self["#{name}_size"] = size
        self["#{name}_type"] = mime
        create_attachment_queue[name] = file
      end

      ##
      # Attachments we need to add after save.
      # For binary String data.
      def create_attachment_raw(name, binary, filename)
        type = MIME::Types.type_for(filename).first
        mime = type ? type.content_type : "application/octet-stream"
        self["#{name}_id"]   = BSON::ObjectId.new
        self["#{name}_name"] = filename
        self["#{name}_size"] = binary.size
        self["#{name}_type"] =  mime
        create_attachment_queue[name] = binary
      end

      ##
      # Save an attachment to Grid
      def create_grid_attachment(name,file)
        data = case
        when file.is_a?(Hash)
          file[:tempfile].read
        else
          file.respond_to?(:read) ? file.read : file
        end
        grid.put(
          data,
          :filename => self["#{name}_name"],
          :content_type => self["#{name}_type"],
          :_id => self["#{name}_id"]
        )
        create_attachment_queue.delete(name)
      end

      ##
      # Attachments we need to remove after save
      def delete_attachment(name,id)
        delete_attachment_queue[name] = id if id.is_a?(BSON::ObjectId)
        self["#{name}_id"]   = nil
        self["#{name}_name"] = nil
        self["#{name}_size"] = nil
        self["#{name}_type"] = nil
      end

      ##
      # Delete an attachment from Grid
      def delete_grid_attachment(name,id)
        grid.delete(id) if id.is_a?(BSON::ObjectId)
        delete_attachment_queue.delete(name)
      end

      ##
      # Create attachments marked for creation
      def create_attachments
        create_attachment_queue.each {|k,v| create_grid_attachment(k,v)}
      end

      ##
      # Delete attachments marked for deletion
      def delete_attachments
        delete_attachment_queue.each {|k,v| delete_grid_attachment(k,v)}
      end

      ##
      # Queues all attachments for deletion
      def queue_delete_attachments
        self.class.attachment_types.each do |name|
          delete_attachment(name, self["#{name}_id"])
        end
      end
    end
  end
end