module MyServiceMock
  def echo(**kwargs)
    kwargs
  end

  def return_a_hash
    {}
  end

  def return_an_array_of_hashes
    []
  end
end
