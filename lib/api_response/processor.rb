# frozen_string_literal: true

module ApiResponse
  class Processor
    extend Dry::Initializer

    param :response
    option :config, default: -> { ApiResponse.config.dup }
    option :options, default: -> { {} }

    def self.call(response, options:, config: ApiResponse.config.dup, &block)
      config = config.dup
      block.call(config) if block_given?
      config = config.update(options)

      new(response, config: config, options: options).call
    end

    def call
      processor = success? ? config.success_processor : config.failure_processor

      processor.new(response, config: config).call
    end

    private

    def success?
      case config.adapter
      when :faraday, :excon
        response.status.to_i < 400
      else
        response.code.to_i < 400
      end
    end
  end
end
