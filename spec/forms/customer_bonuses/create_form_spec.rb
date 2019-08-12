# frozen_string_literal: true

describe CustomerBonuses::CreateForm do
  context '#submit!' do
    subject { form.submit! }

    let!(:primary_currency) { create(:currency, :primary) }
    let(:form) do
      described_class.new(
        amount: customer_bonus.min_deposit,
        **customer_bonus.attributes.symbolize_keys
      )
    end

    let(:customer) { create(:customer) }
    let(:wallet) do
      create(:wallet, customer: customer, currency: primary_currency)
    end
    let(:bonus) { create(:bonus) }
    let(:customer_bonus) do
      build(:customer_bonus,
            customer: customer,
            wallet: wallet,
            original_bonus: bonus)
    end

    context 'without an active bonus' do
      before { subject }

      it 'creates bonus' do
        expect(form.subject).to be_persisted
      end
    end

    context 'with an active bonus' do
      let!(:customer_bonus) do
        create(:customer_bonus,
               customer: customer,
               wallet: wallet)
      end

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
