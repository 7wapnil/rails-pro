describe Payments::Fiat::SafeCharge::CallbackHandler do
  subject { described_class.call(response) }

  let(:response) { { status: 'succeed' } }
  let(:handler) { Payments::Fiat::SafeCharge::Deposits::CallbackHandler }

  context 'redirect to deposit handler' do
    before do
      allow(handler).to receive(:call).with(response)
    end

    it { is_expected.to be_nil }
  end
end
