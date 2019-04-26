# frozen_string_literal: true

describe CustomerBonuses::Create do
  subject { described_class.call(params) }

  let(:params) do
    {
      wallet: wallet,
      original_bonus: bonus,
      amount: amount,
      user: initiator
    }
  end

  let(:amount) { 100 }
  let(:rollover_multiplier) { 5 }
  let(:bonus_value) { 50 }
  let(:calculations) { { bonus: bonus_value, real_money: 100 } }
  let(:bonus) { create(:bonus, rollover_multiplier: rollover_multiplier) }
  let(:customer) { create(:customer) }
  let(:wallet) { create(:wallet, customer: customer) }
  let(:initiator) { create(:user) }

  context 'when customer has no active bonus' do
    before { subject }

    it 'creates new activated bonus' do
      expect(customer.reload.customer_bonus).not_to be_nil
    end

    it 'sets rollover_initial_value correctly' do
      expect(customer.reload.customer_bonus.rollover_initial_value)
        .to eq(amount * rollover_multiplier)
    end
  end

  context 'adds money' do
    let!(:entry_currency_rule) do
      create(:entry_currency_rule, :bonus_change,
             currency: wallet.currency,
             min_amount: 0,
             max_amount: 100)
    end

    let(:comment) do
      "Bonus transaction: #{amount.to_f} #{wallet.currency} " \
      "for #{wallet.customer} by #{initiator}."
    end

    let(:found_entry_request) do
      EntryRequest.bonus_change.find_by(origin: wallet)
    end
    let(:found_entry) { found_entry_request.entry }

    include_context 'asynchronous to synchronous'

    it 'and creates entry request' do
      expect { subject }.to change(EntryRequest, :count).by(1)
    end

    it 'and creates entry request with valid attributes' do
      subject
      expect(found_entry_request).to have_attributes(
        status: EntryRequest::SUCCEEDED,
        amount: amount,
        mode: EntryRequest::SYSTEM,
        initiator: initiator,
        comment: comment,
        origin: wallet,
        currency: wallet.currency,
        customer: wallet.customer
      )
    end

    it 'and creates entry' do
      expect { subject }.to change(Entry, :count).by(1)
    end

    it 'and creates entry with valid attributes' do
      subject
      expect(found_entry).to have_attributes(
        amount: amount,
        wallet: wallet,
        origin: wallet
      )
    end
  end

  context 'when customer has an active bonus' do
    before do
      create(:customer_bonus, :applied, :activated,
             customer: customer, wallet: wallet)
    end

    it 'retains previous customer bonus' do
      expect do
        subject
      rescue StandardError # rubocop:disable Lint/HandleExceptions
      end.not_to change(customer, :active_bonus)
    end

    it 'raises an error' do
      expect { subject }.to raise_error(
        CustomerBonuses::ActivationError,
        I18n.t('errors.messages.customer_has_active_bonus')
      )
    end

    it 'does not create new customer bonus' do
      expect do
        subject
      rescue StandardError # rubocop:disable Lint/HandleExceptions
      end.not_to change(CustomerBonus, :count)
    end
  end

  context 'rollovers' do
    let(:customer_bonus) { wallet.customer_bonus }
    let(:rollover) { bonus_value * rollover_multiplier }

    before do
      allow(BalanceCalculations::Deposit)
        .to receive(:call)
        .and_return(calculations)
      subject
    end

    it 'assigns rollover_initial_value' do
      expect(customer_bonus.rollover_initial_value).to eq(rollover)
    end

    it 'assigns rollover_balance' do
      expect(customer_bonus.rollover_balance).to eq(rollover)
    end
  end
end
