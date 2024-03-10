# frozen_string_literal: true

require 'dry/monads'

module ApiResponse
  class Processor
    class Success
      class ExtractError < StandardError; end

      class StructError < StandardError; end

      include Dry::Monads[:result]
      extend Dry::Initializer

      param :response, type: Types.Interface(:body)
      option :config, default: -> { ApiResponse.config }

      def call
        return response if config.raw_response

        result = extract_from_body
        result = build_struct(result) if config.struct

        config.monad ? Success(result) : result
      end

      private

      def response_body
        @response_body ||= config.parser.new(response, config: config).call
      end

      def extract_from_body
        config.extract_from_body.call(response_body) || response_body
      rescue EncodingError => e
        raise ExtractError, e.message
      rescue StandardError
        response.body
      end

      def build_struct(extracted)
        case extracted
        when Hash then config.struct.new(extracted)
        when Array then extracted.map { |item| config.struct.new(**item) }
        end
      rescue StandardError => e
        raise StructError, e.message
      end
    end
  end
end
