describe Deposits::InitiateHostedDepositService do
  let(:wallet) { create(:wallet) }
  let(:bonus) { create(:bonus) }

  let(:customer) { wallet.customer }
  let(:currency_code) { wallet.currency.code }
  let(:amount) { Faker::Number.number 2 }

  describe '#initialize' do
    subject(:initialized_class) do
      described_class.new(
        customer: customer,
        currency_code: currency_code,
        amount: amount,
        bonus_code: bonus.code
      )
    end

    %w[customer currency_code amount bonus_code].each do |argument|
      it "stores #{argument} as local variable" do
        expect(initialized_class.instance_variable_get("@#{argument}")).not_to be nil
      end
    end
  end
end
