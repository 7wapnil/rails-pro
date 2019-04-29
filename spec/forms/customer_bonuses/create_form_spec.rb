# frozen_string_literal: true

describe CustomerBonuses::CreateForm do
  context '#submit!' do
    subject { described_class.new(subject: customer_bonus).submit! }

    let(:customer) { create(:customer) }
    let(:customer_bonus) do
      build(:customer_bonus, :applied, :activated, customer: customer)
    end

    context 'without an active bonus' do
      before { subject }

      it 'creates bonus' do
        expect(customer_bonus).to be_persisted
      end
    end

    context 'with an active bonus' do
      before do
        create(:customer_bonus, :applied, :activated, customer: customer)
      end

      it 'does not create bonus' do
        subject
      rescue CustomerBonuses::ActivationError
        expect(customer_bonus).not_to be_persisted
      end

      it 'raises an error' do
        expect { subject }.to raise_error(CustomerBonuses::ActivationError)
      end
    end
  end
end
