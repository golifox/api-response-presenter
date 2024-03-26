# frozen_string_literal: true

require 'dry/types'

RSpec.describe ApiResponse::Processor do
  let(:body) { "{\"result\":{\"id\":1}}" }

  before { ApiResponse.reset_config }

  describe '.process' do
    subject { described_class.new(response).call }

    context 'when response respond to .code' do
      let(:success_processor) { instance_double(ApiResponse::Processor::Success) }
      let(:failure_processor) { instance_double(ApiResponse::Processor::Failure) }

      before do
        ApiResponse.configure do |c|
          c.adapter = :not_faraday
        end

        allow(success_processor).to receive(:call)
        allow(failure_processor).to receive(:call)
        allow(ApiResponse::Processor::Success).to receive(:new).and_return(success_processor)
        allow(ApiResponse::Processor::Failure).to receive(:new).and_return(failure_processor)
      end

      context 'when response is success' do
        let(:response) { instance_double('Response', code: 200, body: body) }

        it 'calls success processor' do
          subject
          expect(success_processor).to have_received(:call)
        end
      end

      context 'when response is failure' do
        let(:response) { instance_double('Response', code: 404, body: 'Not found') }

        it 'calls failure processor' do
          subject
          expect(failure_processor).to have_received(:call)
        end
      end
    end

    context 'when response does not respond to .body' do
      let(:response) { instance_double('Response', status: 200) }

      it { expect { subject }.to raise_error(Dry::Types::ConstraintError) }
    end
  end

  describe '.process with default configuration' do
    subject { described_class.new(response).call }

    context 'when response is success' do
      let(:response) { instance_double('Response', status: 200, body: body) }

      it { is_expected.to eq({result: {id: 1}}) }
    end

    context 'when response is failure' do
      let(:response) { instance_double('Response', status: 400, body: 'Not found') }

      it { is_expected.to be_nil }
    end

    context 'when response does not respond to .body' do
      let(:response) { instance_double('Response', status: 200) }

      it { expect { subject }.to raise_error(Dry::Types::ConstraintError) }
    end
  end

  describe '.process with custom configuration' do
    subject { described_class.new(response).call }

    context 'when response is success' do
      before do
        ApiResponse.configure do |c|
          c.struct = OpenStruct
          c.extract_from_body = ->(b) { b[:result] }
          c.monad = true
        end
      end

      let(:response) { instance_double('Response', status: 200, body: body) }

      it { is_expected.to eq(Dry::Monads::Result::Success.new(OpenStruct.new(id: 1))) }
    end

    context 'when response is success and raw_response is true' do
      before do
        ApiResponse.configure do |c|
          c.raw_response = true
        end
      end

      let(:response) { instance_double('Response', status: 200, body: body) }

      it { is_expected.to eq(response) }
    end

    context 'when response is failure' do
      let(:response) { instance_double('Response', status: 400, body: 'Not found') }

      it { is_expected.to be_nil }
    end

    context 'when response is failure and monad is true' do
      context 'when error values not set' do
        before do
          ApiResponse.configure do |c|
            c.monad = true
          end
        end

        let(:response) { instance_double('Response', status: 404, body: 'Not found') }

        it { is_expected.to be_failure }

        it 'returns default error attributes' do
          expect(subject.failure).to include(error:     'External Api error',
                                             error_key: :external_api_error,
                                             status:    :conflict)
        end
      end
    end

    context 'when response is failure and error_json is true' do
      before do
        ApiResponse.configure do |c|
          c.error_json = true
          c.default_return_value = nil
        end
      end

      let(:response) { instance_double('Response', status: 404, body: body) }

      context 'when body can be parsed as json' do
        let(:body) { "{\"error\":\"error\"}" }

        it { is_expected.to eq({error: 'error'}) }
      end

      context 'when body can not be parsed as json' do
        let(:body) { 'Not found' }

        it { is_expected.to eq('Not found') }
      end
    end
  end
end
