# frozen_string_literal: true

require 'dry-monads'

module ApiResponse
  class Processor
    class Failure
      include Dry::Monads[:result]
      extend Dry::Initializer

      param :response, type: Types.Interface(:body)
      option :config, default: -> { ApiResponse.config }

      def call
        return response if config.raw_response
        return build_error_monad if config.monad

        begin
          return response_body if config.error_json
        rescue StandardError
          return config.default_return_value || response.body
        end

        config.default_return_value
      end

      private

      def response_body
        @response_body ||= config.parser.new(response, config: config).call
      end

      def build_error_monad
        status = config.default_status || prepare_status(response)
        error = config.default_error || response_body.fetch(:error, nil) || response_body
        error_key = config.default_error_key || response_body.fetch(:error_key, nil)

        Failure({error: error, error_key: error_key, status: status})
      end

      def prepare_status(response)
        code = case config.adapter
               when :faraday, :excon then response.status
               else response&.code
               end

        prepared_default_status || prepared_response_status(code)
      end

      def prepared_response_status(code)
        config.symbol_status ? ApiResponse::Types::STATUS_CODE_TO_SYMBOL[code.to_i] : code.to_i
      end

      def prepared_default_status
        if config.symbol_status && config.default_status.is_a?(Integer)
          ApiResponse::Types::SYMBOL_TO_STATUS_CODE[config.default_status]
        else
          config.default_status
        end
      end
    end
  end
end
