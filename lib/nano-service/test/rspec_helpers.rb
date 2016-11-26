module NanoService
  module Test
    module RspecHelpers
      def assert_mock_service_parity(service)
        describe "and #{service.test_interface} parity" do
          let(:test_service_module) { service.test_interface }
          let(:test_service) { Class.new.extend(test_service_module) }

          service.instance_methods(true).each do |service_method|
            describe "##{service_method}" do
              it 'should respond' do
                expect(test_service.respond_to?(service_method)).to eq(true)
              end

              it 'should have a matching method signature' do
                expect(service.instance_method(service_method).parameters).to eq(test_service_module.instance_method(service_method).parameters)
              end
            end
          end
        end
      end
    end
  end
end
