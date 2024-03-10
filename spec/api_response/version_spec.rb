# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'VERSION' do
  subject { ApiResponse::VERSION }

  it { is_expected.to eq('0.0.1') }
end
