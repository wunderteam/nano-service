module MockService
  include NanoService::Base

  private

  def private_foo
    'bar'
  end
end
