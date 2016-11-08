require 'spec_helper'

MockService.logger = Logger.new('/dev/null')

describe NanoService::Base do
  describe 'method proxy' do
    it 'proxies instance methods through class method_missing' do
      allow_any_instance_of(MockService).to receive(:foo) { 'bar' }
      expect(MockService.foo).to eq('bar')
    end

    it 'does not proxy private instance methods through class method_missing' do
      expect { MockService.private_foo }.to raise_error(NoMethodError)
    end

    it 'coerces return Hashes to HashWithIndifferentAccess' do
      expect(MockService.return_a_hash.class).to eq(HashWithIndifferentAccess)
    end

    it 'coerces return array of Hashes to array of HashWithIndifferentAccess' do
      expect(MockService.return_an_array_of_hashes.first.class).to eq(HashWithIndifferentAccess)
    end
  end

  describe 'test mode' do
    describe 'proxies methods to Test[service_module_name]' do
      it do
        expect(MockService.test_mode?).to be_falsy

        MockService.test_mode = true
        expect_any_instance_of(TestMockService).to receive(:return_a_hash).once
        MockService.return_a_hash

        MockService.test_mode = false
        expect_any_instance_of(MockService).to receive(:return_a_hash).once
        expect_any_instance_of(TestMockService).not_to receive(:return_a_hash)
        MockService.return_a_hash
      end
    end
  end

  describe 'exception handling' do
    it 'passes exception to handle_exception' do
      allow_any_instance_of(MockService).to receive(:exception!) { raise StandardError }
      allow(MockService).to receive(:handle_exception) { true }
      MockService.exception!

      expect(MockService).to have_received(:handle_exception).with(StandardError)
    end

    # allows service to raise NanoService errors directly
    describe 'NanoService exceptions' do
      it 'catches and re-raises any NanoService exceptions' do
        allow_any_instance_of(MockService).to receive(:exception!) do
          raise NanoService::Error
        end

        expect { MockService.exception! }.to raise_error(NanoService::Error)
      end
    end

    # dynamically defines NanoService errors within service namespace
    describe 'NanoService exceptions' do
      it 'catches and re-raises any NanoService exceptions' do
        allow_any_instance_of(MockService).to receive(:exception!) do
          raise MockService::Error
        end

        expect { MockService.exception! }.to raise_error(MockService::Error)
      end
    end

    # re-packages known errors as NanoService errors
    describe 'known exceptions' do
      it 'catches ActiveRecord::RecordNotFound exceptions and returns RecordNotFound' do
        allow_any_instance_of(MockService).to receive(:exception!) do
          raise ActiveRecord::RecordNotFound
        end

        expect { MockService.exception! }.to raise_error(NanoService::RecordNotFound)
      end

      # TODO: do a better job mocking ActiveRecord errors
      # it 'catches ActiveRecord::RecordInvalid exceptions and returns RecordInvalid' do
      #   allow_any_instance_of(MockService).to receive(:exception!) do
      #     raise ActiveRecord::RecordInvalid, 'foobar'
      #   end
      #
      #   expect{ MockService.exception! }.to raise_error(NanoService::RecordInvalid)
      # end
      #
      # it 'catches ActiveRecord::RecordNotSaved exceptions and returns RecordNotSaved' do
      #   allow_any_instance_of(MockService).to receive(:exception!) do
      #     raise ActiveRecord::RecordNotSaved
      #   end
      #
      #   expect{ MockService.exception! }.to raise_error(NanoService::RecordNotSaved)
      # end

      it 'catches URI::BadURIError (gid) exceptions and returns InvalidGlobalID' do
        allow_any_instance_of(MockService).to receive(:exception!) { GlobalID.new('foo') }

        expect { MockService.exception! }.to raise_error(NanoService::InvalidGlobalID)
      end

      it 'catches URI::GID::MissingModelIdError exceptions and returns InvalidGlobalID' do
        allow_any_instance_of(MockService).to receive(:exception!) { GlobalID.new('gid://foo/Bar') }

        expect { MockService.exception! }.to raise_error(NanoService::InvalidGlobalID)
      end
    end

    # re-rasies unknown errors
    describe 'unknown exception' do
      it 'catches StandardError and returns StandardError' do
        allow_any_instance_of(MockService).to receive(:exception!) { raise StandardError }

        expect { MockService.exception! }.to raise_error(StandardError)
      end
    end
  end
end
