module NanoService
  class Error < StandardError
  end

  class InvalidRecordError < Error
    attr_reader :errors

    def initialize(msg = nil, errors = nil)
      super(msg)
      @errors = ErrorSerializer.serialize(errors)
    end
  end

  class RecordNotFound < Error
  end

  class RecordInvalid < InvalidRecordError
  end

  class RecordNotSaved < InvalidRecordError
  end

  class InvalidGlobalID < Error
  end
end
