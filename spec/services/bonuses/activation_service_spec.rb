describe Bonuses::ActivationService do
  let(:bonus) { create(:bonus) }
  let(:wallet) { create(:wallet) }

  context 'bonus activation' do
    it 'creates new activated bonus' do

      activated_bonus = described_class.call(wallet, bonus)

      expect(activated_bonus).to be_instance_of(ActivatedBonus)
      expect(activated_bonus.customer_id).to eq(wallet.customer_id)
      expect(activated_bonus.original_bonus_id).to eq(bonus.id)
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
