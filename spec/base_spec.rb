require 'spec_helper'

MyService.logger = Logger.new('/dev/null')

describe NanoService::Base do
  assert_mock_service_parity(MyService)

  describe 'method proxy' do
    it 'proxies instance methods through class method_missing' do
      allow_any_instance_of(MyService).to receive(:foo) { 'bar' }
      expect(MyService.foo).to eq('bar')
    end

    it 'does not proxy private instance methods through class method_missing' do
      expect { MyService.private_foo }.to raise_error(NoMethodError)
    end

    it 'coerces return Hashes to HashWithIndifferentAccess' do
      expect(MyService.return_a_hash.class).to eq(HashWithIndifferentAccess)
    end

    it 'coerces return array of Hashes to array of HashWithIndifferentAccess' do
      expect(MyService.return_an_array_of_hashes.first.class).to eq(HashWithIndifferentAccess)
    end
  end

  describe '::after' do
    it 'raises if specified service method is missing' do
      expect {
        callback = proc {}
        MyService.after :echo, :bogus_method, &callback
      }.to raise_error(/unable to register callback for missing method: bogus_method/)
    end

    it 'registers a proc to be called after the specified service method is invoked' do
      expect do |block|
        MyService.after :echo, :return_a_hash, &block
        2.times { MyService.echo(message: 'hi') }
        MyService.return_a_hash
      end.to yield_successive_args(
        [:echo, message: 'hi'],
        [:echo, message: 'hi'],
        :return_a_hash
      )
    end

    it 'registers a proc to be called after any service method is invoked' do
      expect do |block|
        MyService.after &block
        MyService.echo(message: 'hi')
        MyService.return_a_hash
        MyService.return_an_array_of_hashes
      end.to yield_successive_args(
        [:echo, message: 'hi'],
        :return_a_hash,
        :return_an_array_of_hashes
      )
    end
  end

  describe 'test mode' do
    after { MyService.test_mode = false }

    describe '#test_mode=' do
      it 'defaults to false' do
        expect(MyService.test_mode?).to eq(false)
      end

      it 'allows test_mode to be toggled on' do
        MyService.test_mode = true
        expect(MyService.test_mode?).to eq(true)
      end

      it 'allows test_mode to be toggled off' do
        MyService.test_mode = true
        expect(MyService.test_mode?).to eq(true)
        MyService.test_mode = false
        expect(MyService.test_mode?).to eq(false)
      end
    end

    describe '#test_interface' do
      it 'returns the registered test interface' do
        expect(MyService.test_interface).to eq(MyServiceMock)
      end

      describe 'raises TestInterfaceNotRegistered if a test interface is not registered' do
        before { MyService.send(:register_test_interface, nil) }
        after { MyService.send(:register_test_interface, MyServiceMock) }

        it do
          expect { MyService.test_interface }.to raise_error(NanoService::TestInterfaceNotRegistered)
        end
      end
    end

    it 'proxies methods to Test[service_module_name]' do
      MyService.test_mode = true
      expect_any_instance_of(MyServiceMock).to receive(:return_a_hash).once
      MyService.return_a_hash
    end
  end

  describe 'exception handling' do
    it 'passes exception to handle_exception' do
      allow_any_instance_of(MyService).to receive(:exception!) { raise StandardError }
      allow(MyService).to receive(:handle_exception) { true }
      MyService.exception!

      expect(MyService).to have_received(:handle_exception).with(StandardError)
    end

    # allows service to raise NanoService errors directly
    describe 'NanoService exceptions' do
      it 'catches and re-raises any NanoService exceptions' do
        allow_any_instance_of(MyService).to receive(:exception!) do
          raise NanoService::Error
        end

        expect { MyService.exception! }.to raise_error(NanoService::Error)
      end
    end

    # dynamically defines NanoService errors within service namespace
    describe 'NanoService exceptions' do
      it 'catches and re-raises any NanoService exceptions' do
        allow_any_instance_of(MyService).to receive(:exception!) do
          raise MyService::Error
        end

        expect { MyService.exception! }.to raise_error(MyService::Error)
      end
    end

    # re-packages known errors as NanoService errors
    describe 'known exceptions' do
      it 'catches ActiveRecord::RecordNotFound exceptions and returns RecordNotFound' do
        allow_any_instance_of(MyService).to receive(:exception!) do
          raise ActiveRecord::RecordNotFound
        end

        expect { MyService.exception! }.to raise_error(NanoService::RecordNotFound)
      end

      # TODO: do a better job mocking ActiveRecord errors
      # it 'catches ActiveRecord::RecordInvalid exceptions and returns RecordInvalid' do
      #   allow_any_instance_of(MyService).to receive(:exception!) do
      #     raise ActiveRecord::RecordInvalid, 'foobar'
      #   end
      #
      #   expect{ MyService.exception! }.to raise_error(NanoService::RecordInvalid)
      # end
      #
      # it 'catches ActiveRecord::RecordNotSaved exceptions and returns RecordNotSaved' do
      #   allow_any_instance_of(MyService).to receive(:exception!) do
      #     raise ActiveRecord::RecordNotSaved
      #   end
      #
      #   expect{ MyService.exception! }.to raise_error(NanoService::RecordNotSaved)
      # end

      it 'catches URI::BadURIError (gid) exceptions and returns InvalidGlobalID' do
        allow_any_instance_of(MyService).to receive(:exception!) { GlobalID.new('foo') }

        expect { MyService.exception! }.to raise_error(NanoService::InvalidGlobalID)
      end

      it 'catches URI::GID::MissingModelIdError exceptions and returns InvalidGlobalID' do
        allow_any_instance_of(MyService).to receive(:exception!) { GlobalID.new('gid://foo/Bar') }

        expect { MyService.exception! }.to raise_error(NanoService::InvalidGlobalID)
      end
    end

    # re-rasies unknown errors
    describe 'unknown exception' do
      it 'catches StandardError and returns StandardError' do
        allow_any_instance_of(MyService).to receive(:exception!) { raise StandardError }

        expect { MyService.exception! }.to raise_error(StandardError)
      end
    end
  end
end
