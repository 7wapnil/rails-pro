describe ActivatedBonus do
  it { should belong_to(:customer) }
  it { should belong_to(:wallet) }
  it { should belong_to(:original_bonus) }

  context 'instance methods' do
    let(:wallet) { create(:wallet) }
    let(:activated_bonus) do
      create(:activated_bonus, wallet: wallet, customer: wallet.customer)
    end
    it '#ended_at' do
      activated_bonus = create(:activated_bonus)
      duration = activated_bonus.valid_for_days.days
      time_of_end = activated_bonus.created_at + duration
      expect(activated_bonus.ended_at).to eq(time_of_end)
    end

    it '#deactivate!' do
      activated_bonus = create(:activated_bonus)
      activated_bonus.deactivate!

      expect(ActivatedBonus.exists?(activated_bonus.id)).to be_falsey
    end
  end
end
