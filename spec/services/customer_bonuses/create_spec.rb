# frozen_string_literal: true

describe CustomerBonuses::Create do
  subject { described_class.call(params) }

  let(:params) do
    {
      wallet: wallet,
      bonus: bonus,
      amount: amount
    }
  end

  let(:customer) { create(:customer) }
  let(:wallet) { create(:wallet, customer: customer) }
  let(:bonus) { create(:bonus, rollover_multiplier: rollover_multiplier) }
  let(:amount) { 100 }
  let(:rollover_multiplier) { 5 }
  let(:bonus_value) { 50 }
  let(:calculations) { { bonus: bonus_value, real_money: 100 } }
  let(:rollover_value) { (amount * rollover_multiplier).to_d }

  context 'when customer has no active bonus' do
    include_context 'frozen_time'

    before { subject }

    it 'creates new activated bonus' do
      expect(customer.reload.pending_bonus).to have_attributes(
        original_bonus_id: bonus.id,
        customer_id: customer.id,
        wallet_id: wallet.id,
        rollover_balance: rollover_value,
        rollover_initial_value: rollover_value,
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
      subject
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
             original_bonus: bonus,
             expires_at: 1.day.ago,
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
end
