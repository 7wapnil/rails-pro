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

    describe '#expired?' do
      it 'returns false for active bonus' do
        activated_bonus = create(:activated_bonus)
        expect(activated_bonus.expired?).to be_falsey
      end

      it 'returns true for deleted bonus' do
        activated_bonus = create(:activated_bonus, deleted_at: Time.zone.now)
        expect(activated_bonus.expired?).to be_truthy
      end

      it 'returns true for expired bonus' do
        activated_bonus = create(
          :activated_bonus,
          valid_for_days: 1,
          created_at: Time.zone.now - 2.days
        )
        expect(activated_bonus.expired?).to be_truthy
      end
    end

    describe '#status' do
      it 'returns \'active\' for active bonus' do
        activated_bonus = create(:activated_bonus)
        expect(activated_bonus.status).to eq('active')
      end

      it 'returns \'expired\' for deleted bonus' do
        activated_bonus = create(:activated_bonus, deleted_at: Time.zone.now)
        expect(activated_bonus.status).to eq('expired')
      end

      it 'returns \'expired\' for expired bonus' do
        activated_bonus = create(
          :activated_bonus,
          valid_for_days: 1,
          created_at: Time.zone.now - 2.days
        )
        expect(activated_bonus.status).to eq('expired')
      end
    end

    describe '.customer_history' do
      let!(:customer) { create(:customer) }
      let!(:expired_activated_bonus) do
        create(:activated_bonus, customer: customer, deleted_at: Time.zone.now)
      end
      let!(:active_activated_bonus) do
        create(:activated_bonus, customer: customer)
      end

      it 'returns all customer activated bonuses' do
        expect(described_class.customer_history(customer))
          .to match_array([
                            active_activated_bonus,
                            expired_activated_bonus
                          ])
      end
    end
  end
end
