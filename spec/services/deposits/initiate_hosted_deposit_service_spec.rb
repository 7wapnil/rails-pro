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

  describe '#initialize' do
    subject(:initialized_class) { described_class.new(service_call_params) }

    %w[customer currency amount bonus_code].each do |argument|
      it "stores #{argument} as local variable" do
        expect(initialized_class.instance_variable_get("@#{argument}"))
          .not_to be nil
      end
    end
  end

  describe '.call' do
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
      it 'raises ArgumentError' do
        expect do
          described_class.call(
            customer: 1,
            currency: 1,
            amount: '80.3',
            bonus_code: 1
          )
        end.to raise_error(ArgumentError)
      end
    end
  end
end
