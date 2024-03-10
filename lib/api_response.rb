# frozen_string_literal: true

require 'zeitwerk'
loader = Zeitwerk::Loader.for_gem
loader.setup

require 'dry-configurable'
require 'dry-initializer'

module ApiResponse
  extend Dry::Configurable

  setting :adapter, default: :faraday
  setting :monad, default: false
  setting :extract_from_body, default: ->(b) { b }
  setting :struct, default: nil
  setting :raw_response, default: false
  setting :error_json, default: false
  setting :default_return_value, default: nil
  setting :default_status, default: :conflict
  setting :symbol_status, default: true
  setting :default_error_key, default: :external_api_error
  setting :default_error, default: 'External Api error'

  setting :success_processor, default: Processor::Success
  setting :failure_processor, default: Processor::Failure
  setting :parser, default: Parser
  setting :options, default: {}
end
