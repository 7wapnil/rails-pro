describe Bonuses::ActivationService do
  subject { described_class.call(wallet, bonus, amount) }

  let(:amount) { 100 }
  let(:rollover_multiplier) { 5 }
  let(:bonus_value) { 50 }
  let(:calculations) { { bonus: bonus_value, real_money: 100 } }
  let(:bonus) { create(:bonus, rollover_multiplier: rollover_multiplier) }
  let(:customer) { create(:customer) }
  let(:wallet) { create(:wallet, customer: customer) }

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

  context 'when customer has an active bonus' do
    before do
      create(:customer_bonus,
             :applied,
             :activated,
             customer: customer,
             wallet: wallet)
    end

    it 'retains previous customer bonus' do
      expect do
        subject
      rescue StandardError # rubocop:disable Lint/HandleExceptions
      end.not_to change(customer, :active_bonus)
    end

    it 'raises an error' do
      expected_message = I18n.t('errors.messages.customer_has_active_bonus')
      expect { subject }
        .to raise_error(CustomerBonuses::ActivationError, expected_message)
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
      allow(BalanceCalculations::Deposit).to receive(:call)
        .and_return(calculations)
      described_class.call(wallet, bonus, amount)
    end

    it 'assigns rollover_initial_value' do
      expect(customer_bonus.rollover_initial_value).to eq(rollover)
    end

    it 'assigns rollover_balance' do
      expect(customer_bonus.rollover_balance).to eq(rollover)
    end
  end

  context 'activating a repeatable bonus after it expires' do
    before do
      create(:customer_bonus,
             customer: customer,
             original_bonus: bonus,
             expires_at: 1.day.ago)
    end

    it 'raises an error' do
      expect { subject }.not_to raise_error
    end

    it 'activates a bonus' do
      expect(customer.reload.customer_bonus).not_to be_nil
    end
  end

  context 'activating a non-repeatable bonus after it expires' do
    before do
      bonus.update(repeatable: false)
      create(:customer_bonus,
             customer: customer,
             original_bonus: bonus,
             expires_at: 1.day.ago)
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
