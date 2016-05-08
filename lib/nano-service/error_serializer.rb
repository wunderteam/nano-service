module NanoService
  class ErrorSerializer
    def self.serialize(errors)
      if errors && errors.respond_to?(:to_hash) && errors.respond_to?(:full_messages)
        errors.to_hash.merge(full_messages: errors.try(:full_messages))
      else
        {}
      end
    end
  end
end
