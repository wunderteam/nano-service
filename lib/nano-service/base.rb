module NanoService
  module Base
    extend ActiveSupport::Concern

    ANY_METHOD = Object.new
    private_constant :ANY_METHOD

    # dynamically define NanoService exceptions on the including Service module
    included do
      @namespace = Kernel.const_get(name.split('::')[0])

      nano_service_exceptions = NanoService.constants.select do |c|
        klass = NanoService.const_get(c)
        (klass.class === Class) && (klass < StandardError)
      end

      (nano_service_exceptions - @namespace.constants).each do |e|
        @namespace.const_set(e, NanoService.const_get(e))
      end
    end

    module ClassMethods
      def method_missing(method_name, *args, &block)
        if instance_methods.include?(method_name)
          begin
            res = caller_object.send(method_name, *args)

            [method_name, ANY_METHOD].each do |name|
              after_callbacks.fetch(name, []).each { |c| c.call(method_name, *args) }
            end

            if res.is_a?(Hash)
              res.with_indifferent_access
            elsif res.is_a?(Array)
              res.map { |item| item.is_a?(Hash) ? item.with_indifferent_access : item }
            else
              res
            end
          rescue Exception => e
            handle_exception(e)
          end
        else
          super
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        instance_methods.include?(method_name) || super
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
        @logger ||= defined?(Rails) ? Rails.logger : Logger.new(STDOUT)
      end

      def logger=(logger)
        @logger = logger
      end

      def test_mode=(value)
        @test_mode = value
      end

      def test_mode?
        @test_mode == true
      end

      def test_interface
        raise TestInterfaceNotRegistered unless @test_interface
        @test_interface
      end

      def after(*method_names, &block)
        method_names.map!(&:to_sym)
        method_names << ANY_METHOD if method_names.empty?
        method_names.each do |method_name|
          (after_callbacks[method_name] ||= []) << block
        end

        nil
      end

      private

      def after_callbacks
        @after_callbacks ||= { ANY_METHOD => [] }
      end

      def register_test_interface(klass)
        @test_interface = klass
      end

      def caller_object
        if test_mode?
          @test_caller_object ||= Class.new.extend(test_interface)
        else
          @caller_object ||= Class.new.extend(self)
        end
      end
    end
  end
end
