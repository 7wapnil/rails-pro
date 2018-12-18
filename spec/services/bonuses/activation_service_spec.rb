describe Bonuses::ActivationService do
  let(:bonus) { create(:bonus) }
  let(:wallet) { create(:wallet) }

  context 'bonus activation' do
    it 'creates new activated bonus' do
      excluded = %i[created_at deleted_at updated_at id valid_for_days]
      transmitted_attrs = CustomerBonus.column_names & Bonus.column_names

      original_bonus_attrs = transmitted_attrs.map(&:to_sym) - excluded
      customer_bonus = described_class.call(wallet, bonus)

      expect(customer_bonus).to be_instance_of(CustomerBonus)
      expect(customer_bonus.customer_id).to eq(wallet.customer_id)
      expect(customer_bonus.original_bonus_id).to eq(bonus.id)
      original_bonus_attrs.each do |bonus_attribute|
        expect(customer_bonus[bonus_attribute]).to eq(bonus[bonus_attribute])
      end
    end

    it 'removes previous bonus' do
      current = described_class.call(wallet, bonus)
      wallet.reload

      expect(wallet.customer.customer_bonus).to eq(current)
    end
  end
end
