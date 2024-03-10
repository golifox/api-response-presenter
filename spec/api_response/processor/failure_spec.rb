# frozen_string_literal: true

require 'oj'

RSpec.describe ApiResponse::Processor::Failure do
  describe '.call' do
    subject { described_class.new(response).call }

    before { ApiResponse.reset_config }

    let(:body) { "{\"error\":\"Not found\"}" }
    let(:response) { double('Response', body: body, status: 404) }
    let!(:config) { ApiResponse.config }

    context 'when config is default' do
      it { is_expected.to eq(config.default_return_value) }
    end

    context 'when config.raw_response is true' do
      before do
        ApiResponse.configure { |c| c.raw_response = true }
      end

      it { is_expected.to eq(response) }
    end

    context 'when config.monad is true' do
      let(:response) { double('Response', body: body, status: 404) }

      before do
        ApiResponse.configure { |c| c.monad = true }
      end

      it { is_expected.to be_failure }

      it 'returns a monad with default attributes' do
        expect(subject.failure).to include(error:     config.default_error,
                                           error_key: config.default_error_key,
                                           status:    config.default_status)
      end
    end

    context 'when config.error_json is true' do
      before do
        ApiResponse.configure { |c| c.error_json = true }
      end

      let(:expected) { Oj.load(body, mode: :compat, symbol_keys: true) }

      context 'when response body is a JSON' do
        it { is_expected.to eq(expected) }
      end

      context 'when response body is not a JSON' do
        let(:body) { 'Not found' }

        it { is_expected.to eq(body) }
      end
    end

    context 'when default error values are set' do
      before do
        ApiResponse.configure do |c|
          c.default_error = 'Default error'
          c.default_error_key = :default_error_key
          c.default_status = :default_status
        end
      end

      context 'when response is a response that has :status method to return HTTP status code' do
        %i[faraday excon].each do |adapter|
          before do
            ApiResponse.configure do |c|
              c.adapter = adapter
              c.monad = true
            end
          end

          let(:response) { double('Response', body: body, status: 404) }

          it { is_expected.to be_failure }

          it 'returns a monad with default attributes' do
            expect(subject.failure).to include(error:     config.default_error,
                                               error_key: config.default_error_key,
                                               status:    config.default_status)
          end
        end
      end

      context 'when response is a response that has :code method to return HTTP status code' do
        let(:response) { double('Response', body: body, code: 404) }

        before do
          ApiResponse.configure do |c|
            c.adapter = :rest_client
            c.monad = true
          end
        end

        it { is_expected.to be_failure }

        it 'returns a monad with default attributes' do
          expect(subject.failure).to include(error:     config.default_error,
                                             error_key: config.default_error_key,
                                             status:    config.default_status)
        end
      end
    end

    context 'when default error values are not set' do
      let(:body) { "{\"error\":\"Not Found\",\"error_key\":\"not_found\"}" }

      context 'when response is a response that has :status method to return HTTP status code' do
        %i[faraday excon].each do |adapter|
          before do
            ApiResponse.configure do |c|
              c.adapter = adapter
              c.monad = true
              c.default_error = nil
              c.default_error_key = nil
              c.default_status = nil
            end
          end

          let(:response) { double('Response', body: body, status: 400) }

          it { is_expected.to be_failure }

          it 'returns a monad with default attributes' do
            expect(subject.failure).to include(error:     'Not Found',
                                               error_key: 'not_found',
                                               status:    :bad_request)
          end
        end
      end

      context 'when response is a response that has :code method to return HTTP status code' do
        let(:response) { double('Response', body: body, code: 400) }

        before do
          ApiResponse.configure do |c|
            c.adapter = :rest_client
            c.monad = true
            c.default_error = nil
            c.default_error_key = nil
            c.default_status = nil
          end
        end

        it { is_expected.to be_failure }

        it 'returns a monad with default attributes' do
          expect(subject.failure).to include(error:     'Not Found',
                                             error_key: 'not_found',
                                             status:    :bad_request)
        end
      end
    end
  end
end
