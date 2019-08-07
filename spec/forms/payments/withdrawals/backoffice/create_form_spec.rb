# frozen_string_literal: true

describe ::Payments::Withdrawals::Backoffice::CreateForm, type: :model do
  subject { described_class.new(params) }

  let(:params) do
    {
      amount: withdrawal_amount,
      wallet: wallet,
      payment_method: payment_method,
      customer: customer,
      payment_details: payment_details
    }
  end

  let(:successful_deposit) do
    create(:deposit, :credit_card, details: payment_details)
  end
  let!(:successful_deposit_entry_request) do
    create(:entry_request, :deposit, :succeeded, :with_entry,
           mode: payment_method,
           origin: successful_deposit,
           customer: customer)
  end

  let(:payment_method) { ::Payments::Methods::BITCOIN }
  let(:payment_details) { { address: Faker::Bitcoin.address } }
  let(:wallet_type) { Currency::CRYPTO }
  let(:withdrawal_amount) { 50 }
  let(:balance_amount) { withdrawal_amount + 100 }
  let(:customer) do
    # ignore job after new customer creating
    allow(Customers::Summaries::UpdateWorker).to receive(:perform_async)
    create(:customer)
  end
  let(:wallet) do
    create(:wallet, wallet_type.to_sym,
           amount: balance_amount,
           customer: customer)
  end
  let!(:balance) do
    create(:balance, :real_money, amount: balance_amount, wallet: wallet)
  end

  before do
    allow(ENV)
      .to receive(:fetch)
      .with('COINSPAID_MODE', 'test')
      .and_return('prod')
  end

  it { is_expected.to validate_presence_of(:amount) }
  it { is_expected.to validate_presence_of(:wallet) }
  it { is_expected.to validate_presence_of(:payment_method) }
  it { is_expected.to validate_presence_of(:customer) }

  it { is_expected.to allow_value(100).for(:amount) }
  it { is_expected.not_to allow_value(100.999).for(:amount) }

  context 'when random payment method' do
    let(:method) { Faker::String.random(10) }

    it 'successfully verify deposit' do
      expect { subject.validate! }.not_to raise_error
    end
  end

  it do
    allow_any_instance_of(described_class).to receive(:validate_amount)

    expect(subject)
      .to validate_numericality_of(:amount)
      .is_greater_than(0)
  end

  it 'successfully verify withdrawal' do
    expect { subject.validate! }.not_to raise_error
  end

  context 'with pending bonus bets' do
    let(:bet) do
      create(:bet,
             customer: customer,
             status: StateMachines::BetStateMachine::ACCEPTED)
    end
    let(:entry_request) do
      create(:entry_request,
             customer: customer,
             origin: bet)
    end
    let!(:balance_entry_request) do
      create(:balance_entry_request,
             entry_request: entry_request,
             kind: Balance::BONUS)
    end

    it 'has error' do
      subject.validate

      expect(subject.errors).to include(:base)
    end
  end

  context 'raise WithdrawalError' do
    let(:balance_amount) { withdrawal_amount - 10 }
    let(:error_message) do
      'Validation failed: ' \
      "#{I18n.t('errors.messages.backoffice.not_enough_money')}"
    end

    it 'raises error when wallet amount is less than withdrawal amount' do
      expect { subject.validate! }
        .to raise_error(ActiveModel::ValidationError, error_message)
    end
  end
end
