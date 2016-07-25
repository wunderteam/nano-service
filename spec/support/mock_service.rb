module MockService
  include NanoService::Base

  def return_a_hash
    { foo: 'bar' }
  end

  def return_an_array_of_hashes
    [{ foo: 'bar' }, { foo: 'bar' }]
  end

  private

  def private_foo
    'bar'
  end
end
