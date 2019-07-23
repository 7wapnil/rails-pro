# frozen_string_literal: true

describe ::Payments::Crypto::CoinsPaid::SignatureService do
  subject { described_class.new(data: control_data) }

  let(:control_sum_without_data) do
    'ebca4577480feb6bfb568d9b630429a84f1833447949d1982a3526b875a6de1' \
      '4ee89b38162607861199b163e6ed523014e8d32110238ea23a38c1ea060f727ba'
  end
  let(:control_sum_with_data) do
    'c2dba4bc1a5d4aed0cedc800fa8587041af949c4b13bbdf57bcc419f03c42cc' \
      '1570bb193c3b8c2f91568d84e92382e06d04c1072d613b0fcafbf85d2a9192899'
  end
  let(:control_data) { 'kot1q7u154ucexatxhim17tqvl690rzc' }
  let(:secret_key) { '8jm613ha8ymuitm5a2hfi29gwbyy6qp1' }

  before do
    allow(ENV).to receive(:[])
      .with('COINSPAID_SECRET')
      .and_return(secret_key)
  end

  context 'with data' do
    it 'returns correct signature' do
      expect(subject.call).to eq(control_sum_with_data)
    end
  end

  context 'without data' do
    let(:control_data) { '' }

    it 'returns correct signature' do
      expect(subject.call).to eq(control_sum_without_data)
    end
  end
end
