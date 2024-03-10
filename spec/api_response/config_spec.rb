# frozen_string_literal: true

RSpec.describe ApiResponse do
  before(:each) { ApiResponse.reset_config }

  describe '.config' do
    subject { described_class.config }

    let(:default_attributes) do
      {
        adapter:              :faraday,
        raw_response:         false,
        struct:               nil,
        monad:                false,
        error_json:           false,
        extract_from_body:    ->(b) { b },
        default_return_value: nil,
        default_status:       :conflict,
        symbol_status:        true,
        default_error_key:    :external_api_error,
        default_error:        'External Api error'
      }
    end

    it { is_expected.to have_attributes(default_attributes) }
    it { expect(subject.extract_from_body).to be_a(Proc) }
    it { expect(subject.extract_from_body.call('some value')).to eq('some value') }
  end

  describe '.configure' do
    let(:struct) { double('Struct') }
    let(:expected_attributes) do
      {
        adapter:              :rest_client,
        raw_response:         true,
        struct:               struct,
        monad:                true,
        error_json:           true,
        extract_from_body:    ->(b) { b[:result] },
        default_return_value: 'value',
        default_status:       :not_found,
        symbol_status:        false,
        default_error_key:    :object_not_found,
        default_error:        'Not found'
      }
    end

    before do
      described_class.configure do |config|
        config.adapter = expected_attributes[:adapter]
        config.raw_response = expected_attributes[:raw_response]
        config.struct = expected_attributes[:struct]
        config.monad = expected_attributes[:monad]
        config.error_json = expected_attributes[:error_json]
        config.extract_from_body = expected_attributes[:extract_from_body]
        config.default_return_value = expected_attributes[:default_return_value]
        config.default_status = expected_attributes[:default_status]
        config.symbol_status = expected_attributes[:symbol_status]
        config.default_error_key = expected_attributes[:default_error_key]
        config.default_error = expected_attributes[:default_error]
      end
    end

    subject { described_class.config }

    it { is_expected.to have_attributes(expected_attributes) }
  end
end
