# frozen_string_literal: true

describe CustomerBonuses::CreateForm do
  context '#submit!' do
    subject { described_class.new(subject: customer_bonus).submit! }

    let(:customer) { create(:customer) }
    let(:customer_bonus) { build(:customer_bonus, customer: customer) }

    context 'without an active bonus' do
      before { subject }

      it 'creates bonus' do
        expect(customer_bonus).to be_persisted
      end
    end

    context 'with an active bonus' do
      let!(:customer_bonus) { create(:customer_bonus, customer: customer) }

      it 'does not create bonus' do
        expect do
          subject
        rescue CustomerBonuses::ActivationError
        end.not_to change(CustomerBonus, :count)
      end

      it 'raises an error' do
        expect { subject }.to raise_error(CustomerBonuses::ActivationError)
      end
    end
  end
end
