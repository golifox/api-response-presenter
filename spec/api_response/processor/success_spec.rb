# frozen_string_literal: true

class User < Dry::Struct
  include Dry.Types

  attribute :id, Dry::Types['integer']
  attribute :name, Dry::Types['string']
end

RSpec.describe ApiResponse::Processor::Success do
  describe '.call' do
    subject { described_class.new(response).call }

    before { ApiResponse.reset_config }

    let(:body) { '{"id": 1, "name": "John"}' }
    let(:array_body) { '[{"id": 1, "name": "John"}, {"id": 2, "name": "Doe"}]' }
    let(:response_body) { body }
    let(:response) { double('Response', body: response_body) }

    context 'when raw_response is true' do
      before do
        ApiResponse.configure do |config|
          config.raw_response = true
        end
      end

      it { is_expected.to eq(response) }
    end

    context 'when raw_response is false' do
      before do
        ApiResponse.configure do |config|
          config.raw_response = false
        end
      end

      let(:expected) { Oj.load(body, mode: :compat, symbol_keys: true) }

      it { is_expected.to eq(expected) }
    end

    context 'when raw_response is false and struct is set' do
      context 'when response body is a hash' do
        before do
          ApiResponse.configure do |config|
            config.raw_response = false
            config.struct = User
          end
        end

        let(:expected) { User.new(id: 1, name: 'John') }

        it { is_expected.to eq(expected) }
      end

      context 'when response body is an array' do
        let(:response_body) { array_body }
        let(:expected) { [User.new(id: 1, name: 'John'), User.new(id: 2, name: 'Doe')] }

        before do
          ApiResponse.configure do |config|
            config.raw_response = false
            config.struct = User
          end
        end

        it { is_expected.to eq(expected) }
      end

      context 'when response body is not a hash or an array' do
        let(:response_body) { 'John' }

        before do
          ApiResponse.configure do |config|
            config.raw_response = false
            config.struct = User
            config.default_return_value = nil
          end
        end

        it { expect { subject }.to raise_error(ApiResponse::Processor::Success::ExtractError) }
      end

      context 'when response body is an wrong array' do
        let(:response_body) { '[{"id": "1", "name": "John"}, {"id": 2, "name": "Doe"}]' }

        before do
          ApiResponse.configure do |config|
            config.raw_response = false
            config.struct = User
          end
        end

        it { expect { subject }.to raise_error(ApiResponse::Processor::Success::StructError) }
      end
    end

    context 'when extract_from_body is set' do
      before do
        ApiResponse.configure do |config|
          config.extract_from_body = ->(body) { body[:result] }
        end
      end

      context 'when proc called succesfully' do
        let(:response_body) { '{"result": {"id": 1, "name": "John"}}' }
        let(:expected) { Oj.load(response_body, mode: :compat, symbol_keys: true).fetch(:result) }

        it { is_expected.to eq(expected) }
      end

      context 'when proc does not return anything' do
        let(:response_body) { '{"id": 1, "name": "John"}' }
        let(:expected) { Oj.load(response_body, mode: :compat, symbol_keys: true) }

        it { is_expected.to eq(expected) }
      end

      context 'when proc called with error' do
        before do
          ApiResponse.configure do |config|
            config.extract_from_body = ->(_) { raise StandardError }
          end
        end

        let(:response_body) { '{"id""": 1, "name": "John"}' }

        it { expect { subject }.to raise_error(ApiResponse::Processor::Success::ExtractError) }
      end
    end
  end
end
