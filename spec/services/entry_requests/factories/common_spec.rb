# frozen_string_literal: true

describe EntryRequests::Factories::Common do
  subject { described_class.call(origin: bet, **attributes) }

  let(:bet) { create(:bet) }
  let(:amount) { rand(1..100) }
  let(:attributes) do
    {
      kind: EntryRequest::WIN,
      mode: EntryRequest::SYSTEM,
      amount: rand(1..100)
    }
  end

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
  end

  context 'with invalid attributes' do
    let(:attributes) { {} }

    it 'raises validation error' do
      expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
