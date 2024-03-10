# frozen_string_literal: true

module ApiResponse
  class Presenter
    extend Dry::Initializer

    param :response
    option :config, default: -> { ApiResponse.config.dup }
    option :options, type: Types::Hash, default: -> { {} }

    def self.call(response, **options, &block)
      new(response, options: options).call(&block)
    end

    def call(&block)
      if block_given?
        Processor.call(response, config: config, options: options, &block)
      else
        Processor.call(response, config: config, options: options)
      end
    end
  end
end
