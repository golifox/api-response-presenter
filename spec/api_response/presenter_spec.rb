# frozen_string_literal: true

RSpec.describe ApiResponse::Presenter do
  describe '.call' do
    before { ApiResponse.reset_config }

    let(:response) { double('Response', success?: true, status: 200, body: '{"id": 1}') }

    context 'when block is given' do
      subject { described_class.call(response) { |c| c.monad = true } }

      it { is_expected.to be_success }
      it { expect(subject.success).to eq({id: 1}) }
    end

    context 'when block is not given' do
      subject { described_class.call(response) }

      it { is_expected.to eq({id: 1}) }
    end
  end
end
