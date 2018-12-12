describe CustomerBonus do
  it { should belong_to(:customer) }
  it { should belong_to(:wallet) }
  it { should belong_to(:original_bonus) }

  context 'instance methods' do
    let(:wallet) { create(:wallet) }
    let(:customer_bonus) do
      create(:customer_bonus, wallet: wallet, customer: wallet.customer)
    end
    it '#ended_at' do
      customer_bonus = create(:customer_bonus)
      duration = customer_bonus.valid_for_days.days
      time_of_end = customer_bonus.created_at + duration
      expect(customer_bonus.ended_at).to eq(time_of_end)
    end

    it '#deactivate!' do
      customer_bonus = create(:customer_bonus)
      customer_bonus.deactivate!

      expect(CustomerBonus.exists?(customer_bonus.id)).to be_falsey
    end
  end
end
