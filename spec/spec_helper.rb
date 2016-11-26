require 'nano-service'
require 'nano-service/test/rspec_helpers'

Dir[File.expand_path(File.join(File.dirname(__FILE__), 'support', '**', '*.rb'))].each {|f| require f}

RSpec.configure do |config|
  config.extend NanoService::Test::RspecHelpers
end
