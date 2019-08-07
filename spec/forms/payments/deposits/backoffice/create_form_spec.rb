# frozen_string_literal: true

describe ::Payments::Deposits::Backoffice::CreateForm, type: :model do
  subject { described_class.new(params) }

  let(:params) do
    {
      amount: amount,
      wallet: wallet,
      bonus: bonus,
      payment_method: method
    }
  end

  let(:currency) { create(:currency, :primary) }
  let(:wallet) { create(:wallet, :fiat, currency: currency) }
  let(:bonus) { create(:customer_bonus, wallet: wallet) }
  let!(:currency_rule) { create(:entry_currency_rule, currency: currency) }
  let(:min_amount) { currency_rule.min_amount }
  let(:max_amount) { currency_rule.max_amount }
  let(:method) { Payments::Methods::CREDIT_CARD }
  let(:amount) { min_amount + 1 }

  before do
    # ignore job after new customer creating
    allow(Customers::Summaries::UpdateWorker).to receive(:perform_async)
  end

  context 'presence' do
    it { is_expected.to validate_presence_of(:wallet) }
    it { is_expected.to validate_presence_of(:amount) }
    it { is_expected.not_to validate_presence_of(:payment_method) }
    it { is_expected.not_to validate_presence_of(:bonus) }
  end

  context 'when random payment method' do
    let(:method) { Faker::String.random(10) }

    it 'successfully verify deposit' do
      expect { subject.validate! }.not_to raise_error
    end
  end

  context 'amount' do
    before do
      subject.validate
    end

    context 'when less then 0' do
      let(:amount) { -1 }

      it 'has error' do
        expect(subject.errors).to include(:amount)
      end
    end

    context 'when less than min currency rule' do
      let(:amount) { min_amount - 1 }

      it 'has error' do
        expect(subject.errors).to include(:amount)
      end
    end

    context 'when greater than max currency rule' do
      let(:amount) { max_amount + 1 }

      it 'has error' do
        expect(subject.errors).to include(:amount)
      end
    end
  end

  context 'when customer bonus expired' do
    let(:bonus) do
      create(:customer_bonus, status: CustomerBonus::EXPIRED, wallet: wallet)
    end

    it 'has error' do
      subject.validate

      expect(subject.errors).to include(:bonus)
    end
  end
end
