# frozen_string_literal: true

describe EntryRequests::Factories::WinPayout do
  subject { described_class.call(origin: bet, **attributes) }

  let(:winning) { rand(100..500).to_d }
  let(:amount) { rand(10..100).to_d }
  let(:ratio) { 0.75 }

  let(:customer) { create(:customer, :ready_to_bet) }

  let(:attributes) do
    {
      kind: EntryRequest::WIN,
      mode: EntryRequest::INTERNAL,
      amount: winning
    }
  end

  let(:real_money_winning) { (winning * ratio).round(2) }
  let(:bonus_winning) { (winning * (1 - ratio)).round(2) }

  before do
    bet.placement_entry.update(
      real_money_amount: amount * ratio,
      bonus_amount: amount * (1 - ratio)
    )
  end

  context 'with valid attributes' do
    let(:bet) do
      create(:bet, :with_placement_entry,
             customer_bonus: create(:customer_bonus))
    end

    let(:origin_attributes) do
      {
        currency: bet.currency,
        initiator: bet.customer,
        customer: bet.customer,
        origin: bet
      }
    end

    it 'creates entry request' do
      expect { subject }.to change(Entry, :count).by(0)
    end

    it 'creates entry requests' do
      expect { subject }.to change(EntryRequest, :count).by(1)
    end

    it 'assigns passed attributes' do
      expect(subject).to have_attributes(attributes)
    end

    it 'fullfills entry request with origin attributes' do
      expect(subject).to have_attributes(origin_attributes)
    end

    it 'creates valid real money balance entry' do
      # byebug
      expect(subject)
        .to have_attributes(real_money_amount: real_money_winning)
    end

    it 'creates valid bonus balance entry' do
      expect(subject)
        .to have_attributes(bonus_amount: bonus_winning)
    end
  end

  context 'with invalid attributes' do
    let(:attributes) { {} }
    let(:bet) { create(:bet, :with_placement_entry) }

    it 'raises validation error' do
      expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  context 'with expired origin.customer_bonus' do
    let(:bet) do
      create(:bet, :with_placement_entry,
             customer: customer,
             customer_bonus: customer_bonus)
    end
    let(:customer_bonus) do
      create(:customer_bonus, status: CustomerBonus::EXPIRED,
                              customer: customer)
    end

    it 'does not change a bonus balance' do
      expect(subject.bonus_amount).to be_zero
    end

    it 'adjusts entry_request amount' do
      expect(subject.amount)
        .to eq(subject.real_money_amount)
    end
  end

  context 'with complete bonus bet' do
    let(:bet) do
      create(:bet, :with_placement_entry,
             customer: customer,
             customer_bonus: customer_bonus)
    end
    let(:customer_bonus) do
      create(:customer_bonus, status: CustomerBonus::COMPLETED,
                              customer: customer)
    end

    it 'does not create a bonus balance request' do
      expect(subject.bonus_amount).to be_zero
    end

    it 'creates balance entry requests' do
      expect { subject }.to change(EntryRequest, :count).by(1)
    end
  end
end
