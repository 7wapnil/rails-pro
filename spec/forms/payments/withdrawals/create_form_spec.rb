# frozen_string_literal: true

describe ::Payments::Withdrawals::CreateForm, type: :model do
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

  let(:payment_method) { ::Payments::Methods::BITCOIN }
  let(:payment_details) { { address: Faker::Bitcoin.address } }
  let(:withdrawal_amount) { 50 }
  let(:balance_amount) { withdrawal_amount + 100 }
  let(:customer) { create(:customer) }
  let(:wallet) { create(:wallet, amount: balance_amount, customer: customer) }
  let!(:balance) do
    create(:balance, :real_money, amount: balance_amount, wallet: wallet)
  end

  before do
    allow(ENV).to receive(:fetch)
      .with('COINSPAID_MODE', 'test')
      .and_return('prod')
  end

  it { is_expected.to validate_presence_of(:amount) }
  it { is_expected.to validate_presence_of(:wallet) }
  it { is_expected.to validate_presence_of(:payment_method) }
  it { is_expected.to validate_presence_of(:customer) }

  it { is_expected.to allow_value(100).for(:amount) }
  it { is_expected.not_to allow_value(100.999).for(:amount) }

  it do
    subject.payment_details = {}

    expect(subject)
      .to validate_inclusion_of(:payment_method)
      .in_array(::Payments::Withdraw::PAYMENT_METHODS)
  end

  it do
    allow_any_instance_of(described_class).to receive(:validate_amount)

    expect(subject)
      .to validate_numericality_of(:amount)
      .is_greater_than(0)
  end

  context 'credit card' do
    let(:payment_method) { ::Payments::Methods::CREDIT_CARD }
    let(:payment_details) { {} }

    it 'validates presence of holder name and cvv' do
      subject.valid?
      expect(subject.errors).to include(:holder_name, :last_four_digits)
    end

    context 'validates holder name to be not longer than 100 chars' do
      let(:payment_details) { { holder_name: Faker::Lorem.characters(101) } }

      before { subject.valid? }

      it 'and has an error' do
        expect(subject.errors).to include(:holder_name)
      end
    end

    context 'validates valid holder name' do
      let(:payment_details) { { holder_name: 'Test name' } }

      before { subject.valid? }

      it 'and has no errors' do
        expect(subject.errors).not_to include(:holder_name)
      end
    end

    context 'validates last card number digits value is numerical' do
      let(:payment_details) { { last_four_digits: 'notnumber' } }

      before { subject.valid? }

      it 'and has an error' do
        expect(subject.errors).to include(:last_four_digits)
      end
    end

    context 'validates last card number digits value is 4 digits number' do
      let(:payment_details) { { last_four_digits: 123 } }

      before { subject.valid? }

      it 'and has an error' do
        expect(subject.errors).to include(:last_four_digits)
      end
    end

    context 'passes valid last card number digits value' do
      let(:payment_details) { { last_four_digits: 1234 } }

      before { subject.valid? }

      it 'and has no errors' do
        expect(subject.errors).not_to include(:last_four_digits)
      end
    end
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
    let(:error_message) do
      'Validation failed: ' \
      "#{I18n.t('errors.messages.withdrawal.pending_bets_with_bonus')}"
    end

    it 'raises validation error on validate!' do
      expect { subject.validate! }
        .to raise_error(ActiveModel::ValidationError, error_message)
    end
  end

  context 'raise WithdrawalError' do
    let(:balance_amount) { withdrawal_amount - 10 }
    let(:error_message) do
      'Validation failed: ' \
      "#{I18n.t('errors.messages.withdrawal.not_enough_money')}"
    end

    it 'raises error when wallet amount is less than withdrawal amount' do
      expect { subject.validate! }
        .to raise_error(ActiveModel::ValidationError, error_message)
    end
  end
end
