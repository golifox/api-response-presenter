# api-response-presenter
[![Gem Version](https://badge.fury.io/rb/api-response-presenter.svg)](https://badge.fury.io/rb/api-response-presenter) [![Build Status](https://app.travis-ci.com/golifox/api-response-presenter.svg?branch=main)](https://app.travis-ci.com/golifox/api-response-presenter)
[![Coverage Status](https://coveralls.io/repos/github/golifox/api-response-presenter/badge.svg)](https://coveralls.io/github/golifox/api-response-presenter)
[![Inline docs](https://inch-ci.org/github/golifox/api-response-presenter.svg?branch=main)](https://inch-ci.org/github/golifox/api-response-presenter)

The `api-response-presenter` gem provides a flexible and easy-to-use interface for processing API responses using Faraday or
RestClient with the possibility to configure global settings or per-instance settings. It leverages
the `Dry::Configurable` for configurations, ensuring high performance and full test coverage.

## Supported Ruby Versions
This library oficially supports the following Ruby versions:
- MRI `>=2.7.4`

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'api-response-presenter'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install api-response-presenter
```

## Usage

### Configuration

You can configure api_response globally in an initializer or setup block:

```ruby
# config/initializers/api_response.rb

ApiResponse.config.some_option = 'some_value'

# or

ApiResponse.configure do |config|
  config.adapter = :faraday # or :rest_client, :excon, :http
  config.monad = false
  config.extract_from_body = ->(body) { body }
  config.struct = nil
  config.raw_response = false
  config.error_json = false
  config.default_return_value = nil
  config.default_status = :conflict
  config.default_error_key = :external_api_error
  config.default_error = 'External Api error'

  # dependency injection
  config.success_processor = ApiResponse::Processor::Success
  config.failure_processor = ApiResponse::Processor::Failure
  config.parser = ApiResponse::Parser
  config.options = {}
end
```

or on instance config, provide block (see: BasicUsage).

### Basic Example

Here is a basic example of using api_response to process an API response:

```ruby
response = Faraday.get('https://api.example.com/data')
result = ApiResponse::Presenter.call(response) do |config|
  config.monad = true
end

# or 
# Usefull for using in another libraries
result ||= ApiResponse::Presenter.call(response, monad: true)

if result.success?
  puts "Success: #{result.success}"
else
  puts "Error: #{result.failure}"
end

```

### Config options

- `ApiResponse.config.adapter`: response adapter that you are using. 
  - Default: `:faraday`. 
  - Available values: `:rest_client`, `:excon`, `:http` and others. Checks that response respond to `#status` (only Faraday and Excon)
    or `#code` (others)
- `ApiResponse.config.monad` wrap result into [dry-monads](https://github.com/dry-rb/dry-monads) 
  - Default: `false`
  - Example: `ApiResponse::Presenter.call(response, monad: true) # => Success({})` or `Failure({error:, status:, error_key:})`
  - Note: if you use `ApiResponse::Presenter.call` with monad: true, you should use `#success?` and `#failure?` methods to check result
  - Options only for `ApiResponse.config.monad = true`:
    - `ApiResponse.config.default_status` default status for `ApiResponse::Presenter.call` if response is not success. You can provide symbol or integer.
      - Default: `:conflict`
    - `ApiResponse.config.symbol_status` option for symbolize status from response (or default status if it an Integer).
      - Default: `true`
      - Example: `ApiResponse::Presenter.call(response, monad: true, default_status: 500, symbol_status: false) # => Failure({error:, status: 500, error_key:})`
    - `ApiResponse.config.default_error_key` default error key for `ApiResponse::Presenter.call` if response is not success
      - Default: `:external_api_error`
    - `ApiResponse.config.default_error` default error message for `ApiResponse::Presenter.call` if response is not success
      - Default: `'External Api error'`
- `ApiResponse.config.extract_from_body` procedure that is applied to the `response.body` after it has been parsed from JSON string to Ruby hash with symbolize keys. 
  - Default: `->(body) { body }`. 
  - Example lambdas: `->(b) { b.first }`, `->(b) { b.slice(:id, :name) }`, `-> (b) { b.deep_stringify_keys )}`
- `ApiResponse.config.struct` struct for pack your extracted value from body.
  - Default: `nil`
  - Note: packing only into classes with key value constructors (e.g. `MyAwesomeStruct.new(**attrs)`, not `Struct.new(attrs)`)
  - Recommend to use [dry-struct](https://github.com/dry-rb/dry-struct) or [Ruby#OpenStruct](https://ruby-doc.org/stdlib-3.0.0/libdoc/ostruct/rdoc/OpenStruct.html)
- `ApiResponse.config.raw_response` returns raw response, that you passes into class.
    - Default: `false`
    - Example: `ApiResponse::Presenter.call(Faraday::Response<...>, raw_response: true) # => Faraday::Response<...>`
- `ApiResponse.config.error_json` returns error message from response body if it is JSON (parsed with symbolize keys)
  - Default: `false`
  - Example: `ApiResponse::Presenter.call(Response<body: "{\"error\": \"some_error\"}">, error_json: true) # => {error: "some_error"}`
- `ApiResponse.config.default_return_value` default value for `ApiResponse::Presenter.call` if response is not success 
  - Default: `nil`
  - Example: `ApiResponse::Presenter.call(response, default_return_value: []) # => []`

NOTE: You can override global settings on instance config, provide block (see: BasicUsage). Params options has higher priority than global settings and block settings.

### Examples:

#### Interactors:
```ruby
class ExternalApiCaller < ApplicationInteractor
  class Response < Dry::Struct
    attribute :data, Types::Array
  end
  
  def call
    response = RestClient.get('https://api.example.com/data') # => body: "{\"data\": [{\"id\": 1, \"name\": \"John\"}]}"
    ApiResponse::Presenter.call(response) do |config|
      config.adapter = :rest_client
      config.monad = true
      config.struct = Response
      config.default_status = 400 # no matter what status came in fact
      config.symbol_status = true # return :bad_request instead of 400
      config.default_error = 'ExternalApiCaller api error' # instead of response error field (e.g. body[:error])
    end
  end
end

def MyController
  def index
    result = ExternalApiCaller.call
    if result.success?
      render json: result.success # => ExternalApiCaller::Response<data: [{id: 1, name: "John"}]> => {data: [{id: 1, name: "John"}]}
    else
      render json: {error: result.failure[:error]}, status: result.failure[:status] # => {error: "ExternalApiCaller api error"}, status: 400
    end
  end
end
```

#### ExternalApi services

```ruby

class EmployeeApiService
  class Employee < Dry::Struct
    attribute :id, Types::Integer
    attribute :name, Types::String
  end

  def self.get_employees(monad: false, adapter: :faraday, **options)
    # or (params, presenter_options = {})
    response = Faraday.get('https://api.example.com/data', params) # => body: "{\"data\": [{\"id\": 1, \"name\": \"John\"}]}"
    ApiResponse::Presenter.call(response, monad: monad, adapter: adapter) do |c|
      c.extract_from_body = ->(body) { Kaminari.paginate_array(body[:data]).page(1).per(5) }
      c.struct = Employee
      c.default_return_value = []
    end
  end
end

class MyController
  def index
    employees = EmployeeApiService.get_employees(page: 1, per: 5)
    if employees.any?
      render json: employees # => [Employee<id: 1, name: "John">] => [{id: 1, name: "John"}]
    else
      render json: {error: 'No employees found'}, status: 404
    end
  end
end
```


### Customization

#### Processors
You can customize the response processing by providing a block to `ApiResponse::Presenter.call` or redefine global processors and parser:
All of them must implement `.new(response, config: ApiResponse.config).call` method.
You can use not default config in your processor, just pass it as a second named argument.

1. Redefine `ApiResponse::Processor::Success` # contains logic for success response (status/code 100-399)
2. Redefine `ApiResponse::Processor::Failure` # contains logic for failure response (status/code 400-599)
3. Redefine `ApiResponse::Parser` # contains logic for parsing response body (e.g. `Oj.load(response.body)`)

```ruby
class MyClass
  def initialize(response, config: ApiResponse.config)
    @response = response
    @config = config
  end
  
  def call
    # your custom logic
  end
end
```

or with `Dry::Initializer`

```ruby
require 'dry/initializer'

class MyClass
  extend Dry::Initializer
  option :response
  option :config, default: -> { ApiResponse.config }
  
  def call
    # your custom logic
  end
end
```

You can use your custom processor or parser in `ApiResponse::Presenter.call` or redefine in global settings:

```ruby
ApiResponse.config.success_processor = MyClass
ApiResponse.config.failure_processor = MyClass
ApiResponse.config.parser = MyClass
```

or 

```ruby
ApiResponse::Presenter.call(response, success_processor: MyClass, failure_processor: MyClass, parser: MyClass)
```

#### Options

Also you can add custom options to `ApiResponse.config.options = {}` and use it in your processor or parser:

```ruby
ApiResponse.config do |config| 
  config.options[:my_option] = 'my_value'
  config.options[:my_another_option] = 'my_another_value'
end
```

or 
    
```ruby
ApiResponse::Presenter.call(response, success_processor: MyClass, options: {my_option: 'my_value', my_another_option: 'my_another_value'})
```

Example:

```ruby

class MyCustomParser
  attr_reader :response, :config

  def initialize(response, config: ApiResponse.config)
    @response = response
    @config = config
  end

  def call
    JSON.parse(response.body, symbolize_names: true) # or Oj.load(response.body, symbol_keys: true)
  rescue JSON::ParserError => e
    raise ::ParseError.new(e) if config.options[:raise_on_failure]
    response.body
  end
end

class MyCustomFailureProcessor
  class BadRequestError < StandardError; end

  attr_reader :response, :config

  def initialize(response, config: ApiResponse.config)
    @response = response
    @config = config
  end

  def call
    parsed_body = config.parser.new(response).call
    raise BadRequestError.new(parsed_body) if config.options[:raise_on_failure]

    {error: parsed_body, status: response.status || config.default_status, error_key: :external_api_error}
  end
end

ApiResponse.config do |config|
  config.failure_processor = MyCustomFailureProcessor
  config.parser = MyCustomParser
  config.options[:raise_on_failure] = true
end

response = Faraday.get('https://api.example.com/endpoint_that_will_fail')
ApiResponse::Presenter.call(response) # => raise BadRequestError
```

## Contributing

Bug reports and pull requests are welcome on [GitHub](https://github.com/golifox/api_response.git)

## License
See `LICENSE` file.


