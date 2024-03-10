# frozen_string_literal: true

require 'oj'

module ApiResponse
  class Parser
    extend Dry::Initializer

    param :response, type: Types.Interface(:body)
    option :config, default: -> { ApiResponse.config }

    def call
      Oj.load(response.body, mode: :compat, symbol_keys: true)
    end
  end
end
