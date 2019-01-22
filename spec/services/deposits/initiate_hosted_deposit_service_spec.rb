describe Deposits::InitiateHostedDepositService do
  let(:wallet) { create(:wallet) }
  let(:bonus) { create(:bonus) }

  let(:customer) { wallet.customer }
  let(:currency) { wallet.currency }
  let(:amount) { Faker::Number.decimal(2, 2) }

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
      expect(subject).to be_a EntryRequest
    end

    it 'returns entry request with correct attributes' do
      expect(subject).to have_attributes(
        status: EntryRequest::INITIAL,
        amount: amount.to_d,
        initiator: customer,
        customer: customer,
        currency: currency,
        mode: EntryRequest::SYSTEM,
        kind: EntryRequest::DEPOSIT
      )
    end

    context 'when business rules broken' do
      let(:error_message) { Faker::Lorem.sentence(5) }

      before do
        allow_any_instance_of(described_class)
          .to receive('validate_business_rules!') {
                raise Deposits::InvalidDepositRequestError, error_message
              }
      end

      it 'returns failed entry request with correct attributes' do
        expect(subject).to have_attributes(
          status: EntryRequest::FAILED,
          result: { 'message' => error_message },
          mode: EntryRequest::SYSTEM,
          kind: EntryRequest::DEPOSIT
        )
      end
    end
  end
end
