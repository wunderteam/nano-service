module NanoService
  module Base
    extend ActiveSupport::Concern

    # dynamically define NanoService exceptions on the including Service module
    included do
      @namespace = Kernel.const_get(name.split('::')[0])
      exceptions = NanoService.constants.select { |c| NanoService.const_get(c) < StandardError }

      (exceptions - @namespace.constants).each do |e|
        @namespace.const_set(e, NanoService.const_get(e))
      end
    end

    module ClassMethods
      def caller_object
        @caller_object ||= Class.new.extend(self)
      end

      def method_missing(method_name, *args, &block)
        if instance_methods.include?(method_name)
          begin
            caller_object.send(method_name, *args)
          rescue Exception => e
            handle_exception(e)
          end
        else
          super
        end
      end

      def handle_exception(e)
        log_error(e)

        case e
        when ActiveRecord::RecordNotFound
          raise RecordNotFound, e.message
        when ActiveRecord::RecordInvalid
          raise RecordInvalid.new("#{e.record.class.name} #{e.message}", e.record.errors)
        when ActiveRecord::RecordNotSaved
          raise RecordNotSaved.new("#{e.record.class.name} #{e.message}", e.record.errors)
        when URI::BadURIError
          raise e.message.include?('gid') ? InvalidGlobalID.new(e.message) : e
        when URI::GID::MissingModelIdError
          raise InvalidGlobalID, e.message
        else
          raise e
        end
      end

      def log_error(e, msg = nil)
        logger.error "[#{@namespace}] #{msg}: #{e.message}"
      end

      def logger
        @logger ||= Rails.logger
      end
    end
  end
end
