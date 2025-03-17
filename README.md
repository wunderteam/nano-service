[![Build Status](https://circleci.com/gh/wunderteam/nano-service.svg?style=svg)](https://circleci.com/gh/wunderteam/nano-service)

# NanoService Prototype
A thin module wrapper for helping enforce service boundaries.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'nano-service'
```

And then execute:

```
$ bundle install
```

## Usage

NanoService provides a simple way to define service modules with consistent error handling, method proxying, and test support.

### Basic Usage

```ruby
# Define your service module
module UserService
  include NanoService::Base
  
  # Service implementation methods
  def find(id)
    user = User.find(id)
    { id: user.id, name: user.name }
  end
  
  def create(attributes)
    user = User.create!(attributes)
    { id: user.id, name: user.name }
  end
end

# Call service methods directly on the module
UserService.find(123)
UserService.create(name: "Jane Doe")
```

### Exception Handling

NanoService automatically converts common exceptions:
- `ActiveRecord::RecordNotFound` becomes `NanoService::RecordNotFound`
- `ActiveRecord::RecordInvalid` becomes `NanoService::RecordInvalid`

### Testing Support

```ruby
# Define a mock implementation
module UserServiceMock
  def find(id)
    { id: id, name: "Test User" }
  end
end

# Register the mock interface in your service
module UserService
  include NanoService::Base
  register_test_interface UserServiceMock
end

# Enable test mode
UserService.test_mode = true

# Now service calls use the mock implementation
UserService.find(123) # => { id: 123, name: "Test User" }
```

### After-Method Callbacks

```ruby
# Register a callback after specific methods
UserService.after(:create) do |method_name, *args|
  puts "User created with arguments: #{args.inspect}"
end

# Or register a callback for any method
UserService.after do |method_name, *args|
  puts "Method #{method_name} called with arguments: #{args.inspect}"
end
```

## TODO
- additional test coverage for dynamic exception definition
- explore options for more flexible exception mapping
