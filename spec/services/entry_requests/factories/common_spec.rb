# frozen_string_literal: true

describe EntryRequests::Factories::Common do
  subject { described_class.call(origin: bet, **attributes) }

  let(:bet) { create(:bet, :with_placement_entry) }
  let(:winning) { rand(100..500).to_f }
  let(:amount) { rand(10..100).to_f }
  let(:ratio) { 0.75 }

  let!(:wallet_balance) do
    bet.placement_entry.update(
      real_money_amount: amount * ratio,
      bonus_amount: amount * (1 - ratio)
    )
  end

  let(:attributes) do
    {
      kind: EntryRequest::WIN,
      mode: EntryRequest::INTERNAL,
      amount: winning
    }
  end

  let(:real_money_winning) { (winning * ratio).round(2) }
  let(:bonus_winning) { (winning * (1 - ratio)).round(2) }

  context 'with valid attributes' do
    let(:origin_attributes) do
      {
        currency: bet.currency,
        initiator: bet.customer,
        customer: bet.customer,
        origin: bet
      }
    end

    it 'creates entry request' do
      expect { subject }.to change(EntryRequest, :count).by(1)
    end

    it 'assigns passed attributes' do
      expect(subject).to have_attributes(attributes)
    end

    it 'fullfills entry request with origin attributes' do
      expect(subject).to have_attributes(origin_attributes)
    end

    it 'creates valid real money balance entry request' do
      expect(subject)
        .to have_attributes(real_money_amount: real_money_winning)
    end

    it 'creates valid bonus balance entry request' do
      expect(subject)
        .to have_attributes(bonus_amount: bonus_winning)
    end
  end

  context 'with invalid attributes' do
    let(:attributes) { {} }

    it 'raises validation error' do
      expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
