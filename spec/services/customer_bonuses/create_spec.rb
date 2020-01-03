# frozen_string_literal: true

describe CustomerBonuses::Create do
  subject { described_class.call(params) }

  let!(:primary_currency) { create(:currency, :primary) }

  let(:params) do
    {
      wallet: wallet,
      bonus: bonus,
      amount: amount
    }
  end

  let(:customer) { create(:customer) }
  let(:wallet) do
    create(:wallet, customer: customer, currency: primary_currency)
  end
  let(:bonus) { create(:bonus, rollover_multiplier: rollover_multiplier) }
  let(:amount) { 100 }
  let(:rollover_multiplier) { 5 }
  let(:bonus_value) { 50 }
  let(:calculations) { { bonus_amount: bonus_value, real_money_amount: 100 } }
  let(:rollover_value) { (bonus_value * rollover_multiplier).to_d }

  context 'when customer has no active bonus' do
    include_context 'frozen_time'

    before { subject }

    it 'creates new activated bonus' do
      expect(customer.reload.pending_bonus).to have_attributes(
        original_bonus_id: bonus.id,
        customer_id: customer.id,
        wallet_id: wallet.id,
        rollover_balance: nil,
        rollover_initial_value: nil,
        code: bonus.code,
        kind: bonus.kind,
        rollover_multiplier: bonus.rollover_multiplier,
        max_rollover_per_bet: bonus.max_rollover_per_bet,
        max_deposit_match: bonus.max_deposit_match,
        min_odds_per_bet: bonus.min_odds_per_bet,
        min_deposit: bonus.min_deposit,
        valid_for_days: bonus.valid_for_days,
        percentage: bonus.percentage,
        status: CustomerBonus::INITIAL
      )
    end

    it 'activated bonus expires at the same time as original bonus' do
      expect(customer.reload.pending_bonus.expires_at.to_s)
        .to eq(bonus.expires_at.to_s)
    end
  end

  context 'when customer has an active bonus' do
    let!(:customer_bonus) do
      create(:customer_bonus, customer: customer, wallet: wallet)
    end

    it 'retains previous customer bonus' do
      expect do
        subject
      rescue StandardError
      end.not_to change { customer.reload.active_bonus }
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
      rescue StandardError
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

      subject.activate(create(:entry, bonus_amount: bonus_value))
    end

    it 'assigns rollover_initial_value' do
      expect(customer_bonus.rollover_initial_value).to eq(rollover)
    end

    it 'assigns rollover_balance' do
      expect(customer_bonus.rollover_balance).to eq(rollover)
    end
  end

  context 'creating a repeatable bonus after it expires' do
    before do
      create(:customer_bonus,
             customer: customer,
             wallet: wallet,
             original_bonus: bonus,
             expires_at: 1.day.ago,
             status: CustomerBonus::EXPIRED)
    end

    it 'does not raise an error' do
      expect { subject }.not_to raise_error
    end

    it 'activates a bonus' do
      subject
      expect(customer.reload.pending_bonus).not_to be_nil
    end
  end

  context 'creating a non-repeatable bonus after it expires' do
    before do
      bonus.update(repeatable: false)
      create(:customer_bonus,
             customer: customer,
             wallet: wallet,
             original_bonus: bonus,
             status: CustomerBonus::EXPIRED)
    end

    it 'raises an error' do
      expected_message = I18n.t(
        'errors.messages.repeated_bonus_activation'
      )
      expect { subject }
        .to raise_error(CustomerBonuses::ActivationError, expected_message)
    end
  end

  context 'creating a non-repeatable bonus after it failed' do
    before do
      bonus.update(repeatable: false)
      create(:customer_bonus,
             customer: customer,
             wallet: wallet,
             original_bonus: bonus,
             status: CustomerBonus::FAILED)
    end

    it 'does not raise an error' do
      expect { subject }.not_to raise_error
    end

    it 'creates a bonus' do
      expect { subject }.to change(CustomerBonus, :count)
    end
  end

  context 'somehow creating an expired bonus' do
    let(:bonus) { create(:bonus, expires_at: 1.day.ago) }

    it 'creates an expired CustomerBonus' do
      subject
      expect(subject).to be_expired
    end
  end

  context 'with de-facto expired active bonus' do
    let!(:expiring_bonus) do
      create(
        :customer_bonus,
        :with_positive_bonus_balance,
        customer: customer,
        wallet: wallet,
        original_bonus: bonus,
        activated_at: 2.years.ago,
        status: CustomerBonus::ACTIVE
      )
    end

    before { subject }

    it 'creates a new customer bonus' do
      expect(customer.pending_bonus).to be_present
    end

    it 'expires the old customer bonus' do
      expect(expiring_bonus.reload).to be_expired
    end
  end

  context 'with crypto wallet' do
    let(:exchange_rate) { 0.1 }
    let(:crypto_currency) do
      create(:currency, :crypto, exchange_rate: exchange_rate)
    end
    let(:wallet) do
      create(:wallet, customer: customer, currency: crypto_currency)
    end
    let(:customer_bonus) { wallet.customer_bonus }

    it 'sets customer bonus attributes in crypto currency' do
      subject

      expect(customer_bonus).to have_attributes(
        max_rollover_per_bet: bonus.max_rollover_per_bet * exchange_rate,
        max_deposit_match: bonus.max_deposit_match * exchange_rate,
        min_deposit: bonus.min_deposit * exchange_rate
      )
    end
  end

  context 'converter for rollover initial value' do
    let(:amount) { bonus.min_deposit }
    let(:currency) { create(:currency, :with_low_exchange_rate) }
    let(:wallet) do
      create(:wallet, customer: customer, currency: currency)
    end

    it 'raise error if converted sum less than min deposit' do
      expect { subject }.to raise_error(
        CustomerBonuses::ActivationError,
        I18n.t('errors.messages.bonus_minimum_requirements_failed')
      )
    end

    context 'with right amount' do
      let(:amount) { (bonus.min_deposit * currency.exchange_rate).ceil }
      let(:entry) { create(:entry, bonus_amount: bonus_value) }

      before { subject.activate(entry) }

      it 'checking rollover value with right amount' do
        expect(customer.reload.pending_bonus).to have_attributes(
          rollover_initial_value: rollover_value,
          status: CustomerBonus::INITIAL
        )
      end
    end
  end
end
