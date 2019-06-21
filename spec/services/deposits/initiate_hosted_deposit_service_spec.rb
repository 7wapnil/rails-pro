describe Deposits::InitiateHostedDepositService do
  let(:wallet) { create(:wallet) }
  let(:bonus) { create(:bonus) }

  let(:customer) { wallet.customer }
  let(:currency) { wallet.currency }
  let(:amount) { Faker::Number.decimal(2, 2).to_d }

  let(:service_call_params) do
    {
      customer: customer,
      currency: currency,
      amount: amount,
      bonus_code: bonus.code
    }
  end

  describe '#call' do
    subject { described_class.call(service_call_params) }

    it 'returns entry request' do
      expect(subject).to be_an EntryRequest
    end

    it 'returns entry request with correct attributes' do
      expect(subject).to have_attributes(
        status: EntryRequest::INITIAL,
        amount: (amount + amount / 100 * bonus.percentage).to_d,
        initiator: customer,
        customer: customer,
        currency: currency,
        mode: EntryRequest::SAFECHARGE_UNKNOWN,
        kind: EntryRequest::DEPOSIT
      )
    end

    context 'when amount sent as a string' do
      let(:amount) { '80.3' }

      it 'raises ArgumentError' do
        expect { subject }.to raise_error(ArgumentError)
      end
    end

    context 'when bonus activation fails' do
      before do
        allow(CustomerBonuses::Create)
          .to receive(:call)
          .and_raise(CustomerBonuses::ActivationError)
      end

      it 'creates an entry request' do
        expect { subject }.to change(EntryRequest, :count).by(1)
      end

      it 'fails the entry request right away' do
        subject
        expect(EntryRequest.last).to be_failed
      end
    end
  end
end
