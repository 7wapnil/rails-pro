# frozen_string_literal: true

describe Bonuses::ActivationService do
  subject { described_class.call(params) }

  let(:params) do
    {
      wallet: wallet,
      bonus: bonus,
      amount: amount,
      initiator: initiator
    }
  end

  let(:customer) { create(:customer) }
  let(:wallet) { create(:wallet, customer: customer) }
  let(:bonus) { create(:bonus, rollover_multiplier: rollover_multiplier) }
  let(:amount) { 100 }
  let(:initiator) { create(:user) }
  let(:rollover_multiplier) { 5 }
  let(:bonus_value) { 50 }
  let(:calculations) { { bonus: bonus_value, real_money: 100 } }
  let(:rollover_value) { (amount * rollover_multiplier).to_d }

  context 'adds money' do
    let!(:entry_currency_rule) do
      create(:entry_currency_rule, :bonus_change,
             currency: wallet.currency,
             min_amount: 0,
             max_amount: 100)
    end

    let(:comment) do
      "Bonus transaction: #{amount} #{wallet.currency} " \
      "for #{wallet.customer} by #{initiator}."
    end

    let(:created_customer_bonus) { bonus.customer_bonuses.last }
    let(:found_entry_request) do
      EntryRequest.bonus_change.find_by(origin: created_customer_bonus)
    end
    let(:found_entry) { found_entry_request.entry }

    include_context 'asynchronous to synchronous'

    it 'and creates customer bonus' do
      expect { subject }.to change(CustomerBonus, :count).by(1)
    end

    it 'and creates entry request' do
      expect { subject }.to change(EntryRequest, :count).by(1)
    end

    it 'and creates entry request with valid attributes' do
      subject
      expect(found_entry_request).to have_attributes(
        status: EntryRequest::SUCCEEDED,
        amount: amount.to_d,
        mode: EntryRequest::INTERNAL,
        initiator: initiator,
        comment: comment,
        origin: created_customer_bonus,
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
        amount: amount.to_d,
        wallet: wallet,
        origin: created_customer_bonus
      )
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

  context 'activating a repeatable bonus after it expires' do
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
      expect(customer.reload.customer_bonuses).not_to be_empty
    end
  end

  context 'activating a non-repeatable bonus after it expires' do
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
