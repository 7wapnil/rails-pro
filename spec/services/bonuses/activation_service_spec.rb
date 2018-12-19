describe Bonuses::ActivationService do
  let(:amount) { 100 }
  let(:rollover_multiplier) { 5 }
  let(:bonus_value) { 50 }
  let(:calculations) { { bonus: bonus_value, real_money: 100 } }
  let(:bonus) { create(:bonus, rollover_multiplier: rollover_multiplier) }
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
      customer = wallet.customer
      previous = CustomerBonus.create(original_bonus: bonus,
                                      customer: customer,
                                      wallet: wallet)
      current = described_class.call(wallet, bonus)
      wallet.reload

      expect(wallet.customer.customer_bonus).to eq(current)
      expect(CustomerBonus.exists?(previous.id)).to be_falsey
    end

    context 'rollovers' do
      let(:customer_bonus) { wallet.customer_bonus }
      let(:rollover) { bonus_value * rollover_multiplier }

      before do
        allow(BalanceCalculations::Deposit).to receive(:call)
          .and_return(calculations)
        described_class.call(wallet, bonus, amount)
      end

      it 'assigns rollover_initial_value' do
        expect(customer_bonus.rollover_initial_value).to eq(rollover)
      end

      it 'assigns rollover_balance' do
        expect(customer_bonus.rollover_balance).to eq(rollover)
      end
    end
  end
end
