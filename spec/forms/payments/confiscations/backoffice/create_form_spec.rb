# frozen_string_literal: true

describe ::Payments::Confiscations::Backoffice::CreateForm, type: :model do
  subject { described_class.new(params) }

  let(:params) do
    {
      amount: confiscation_amount,
      wallet: wallet,
      payment_method: payment_method,
      customer: customer,
      payment_details: payment_details,
      initiator: initiator
    }
  end

  let(:initiator) { create(:user) }
  let(:successful_deposit) do
    create(:deposit, :credit_card, details: payment_details)
  end
  let!(:successful_deposit_entry_request) do
    create(:entry_request, :deposit, :succeeded, :with_entry,
           mode: payment_method,
           origin: successful_deposit,
           customer: customer)
  end

  let(:payment_method) { ::EntryRequest::CASHIER }
  let(:payment_details) { { address: Faker::Bitcoin.address } }
  let(:wallet_type) { Currency::FIAT }
  let(:crypto_type) { Currency::CRYPTO }
  let(:confiscation_amount) { 50 }
  let(:balance_amount) { confiscation_amount + 100 }
  let(:customer) do
    # ignore job after new customer creating
    allow(Customers::Summaries::UpdateWorker).to receive(:perform_async)
    create(:customer)
  end
  let(:wallet) do
    create(
      :wallet, wallet_type.to_sym,
      amount: balance_amount,
      real_money_balance: balance_amount,
      customer: customer
    )
  end

  it { is_expected.to validate_presence_of(:amount) }
  it { is_expected.to validate_presence_of(:wallet) }
  it { is_expected.to validate_presence_of(:payment_method) }
  it { is_expected.to validate_presence_of(:customer) }

  it { is_expected.to allow_value(100).for(:amount) }
  it { is_expected.not_to allow_value(100.999).for(:amount) }

  it 'successfully verify confiscation' do
    expect { subject.validate! }.not_to raise_error
  end

  context 'raise ConfiscationError when initiator is blank' do
    let(:initiator) { nil }

    it 'raises error when initiator is blank' do
      expect { subject.validate! }.to raise_error(ActiveModel::ValidationError)
    end
  end

  context 'raise ConfiscationError when initiator is customer' do
    let(:initiator) { nil }

    it 'raises error when initiator is customer' do
      expect { subject.validate! }.to raise_error(ActiveModel::ValidationError)
    end
  end

  context 'if balance is negative' do
    let(:balance_amount) { -50 }

    it 'successfully verify confiscation' do
      expect { subject.validate! }.not_to raise_error
    end
  end

  context 'if confiscation amount more than real money with active bonus' do
    let!(:customer_bonus) do
      create(:customer_bonus, customer: customer, wallet: wallet)
    end
    let(:balance_amount) { 100 }
    let(:confiscation_amount) { balance_amount + 50 }

    it 'raises error when confiscate from wallet which have bonus' do
      expect { subject.validate! }.to raise_error(ActiveModel::ValidationError)
    end

    context 'when confiscate from another wallet' do
      let(:balance_amount) { 100 }
      let(:confiscation_amount) { balance_amount + 50 }
      let(:another_wallet) do
        create(
          :wallet, crypto_type.to_sym,
          amount: balance_amount,
          real_money_balance: balance_amount,
          customer: customer
        )
      end
      let!(:customer_bonus) do
        create(:customer_bonus, customer: customer, wallet: another_wallet)
      end

      it 'does not raise error' do
        expect { subject.validate! }.not_to raise_error
      end
    end
  end
end
