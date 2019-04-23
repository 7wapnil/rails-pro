describe CustomerBonuses::CreateForm do
  context '#validate!' do
    subject { described_class.new(subject: customer_bonus) }
    let(:customer_bonus) do
      build(:customer_bonus, :applied, :activated, customer: customer)
    end
    let(:customer) { create(:customer) }

    context 'without an active bonus' do
      it 'does not raise any errors' do
        expect { subject }.not_to raise_error
      end
    end

    context 'with an active bonus' do
      before do
        create(:customer_bonus, :applied, :activated, customer: customer)
      end

      it 'raises an error' do
        expect { subject }.not_to raise_error(CustomerBonuses::ActivationError)
      end
    end
  end
end
