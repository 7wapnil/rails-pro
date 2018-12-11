describe Bonuses::ActivationService do
  let(:bonus) { create(:bonus) }
  let(:wallet) { create(:wallet) }

  context 'bonus activation' do
    it 'creates new activated bonus' do
      excluded = %i[created_at deleted_at updated_at id valid_for_days]
      transmitted_attrs = ActivatedBonus.column_names & Bonus.column_names

      original_bonus_attrs = transmitted_attrs.map(&:to_sym) - excluded
      activated_bonus = described_class.call(wallet, bonus)

      expect(activated_bonus).to be_instance_of(ActivatedBonus)
      expect(activated_bonus.customer_id).to eq(wallet.customer_id)
      expect(activated_bonus.original_bonus_id).to eq(bonus.id)
      original_bonus_attrs.each do |bonus_attribute|
        expect(activated_bonus[bonus_attribute]).to eq(bonus[bonus_attribute])
      end
    end

    it 'removes previous bonus' do
      customer = wallet.customer
      previous = ActivatedBonus.create(original_bonus: bonus,
                                       customer: customer,
                                       wallet: wallet)
      current = described_class.call(wallet, bonus)
      wallet.reload

      expect(wallet.customer.activated_bonus).to eq(current)
      expect(ActivatedBonus.exists?(previous.id)).to be_falsey
    end
  end
end
