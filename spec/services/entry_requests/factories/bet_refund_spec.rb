# frozen_string_literal: true

describe EntryRequests::Factories::BetRefund do
  subject { described_class.call(bet: bet) }

  let(:bet) { create(:bet, :with_placement_entry, :with_active_bonus) }
  let(:placement_entry) { bet.placement_entry }

  let(:general_attributes) do
    {
      kind: EntryRequest::REFUND,
      mode: EntryRequest::INTERNAL,
      currency: bet.currency,
      initiator: bet.customer,
      customer: bet.customer,
      origin: bet
    }
  end
  let(:balance_attributes) do
    {
      amount: placement_entry.amount.abs,
      real_money_amount: placement_entry.real_money_amount.abs,
      bonus_amount: placement_entry.bonus_amount.abs
    }
  end

  it 'fullfills entry request with general attributes' do
    expect(subject).to have_attributes(general_attributes)
  end

  it 'fullfills entry request with balance attributes' do
    expect(subject).to have_attributes(balance_attributes)
  end

  context 'with void factor' do
    let(:bet) do
      create(:bet, :with_placement_entry, :settled, :with_active_bonus,
             void_factor: void_factor)
    end
    let(:void_factor) { 0.5 }
    let(:original_balance_attributes) do
      {
        amount: placement_entry.amount.abs,
        real_money_amount: placement_entry.real_money_amount.abs,
        bonus_amount: placement_entry.bonus_amount.abs
      }
    end
    let(:balance_attributes) do
      original_balance_attributes.transform_values do |amount|
        (amount * void_factor).round(Bet::PRECISION)
      end
    end

    it 'fullfills entry request with correct balance attributes' do
      expect(subject).to have_attributes(balance_attributes)
    end
  end
end
