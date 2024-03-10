# frozen_string_literal: true

require 'api_response'

support_dir = File.expand_path('support/**/*.rb', __dir__)
Dir.glob(support_dir).each { |file| require file }

require 'oj'
require 'dry-struct'
require 'dry-types'
