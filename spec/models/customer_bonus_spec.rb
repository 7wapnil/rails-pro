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

    it '#close!' do
      customer_bonus = create(:customer_bonus)
      deactivation_strategy = double('DeactivationStrategy')
      allow(deactivation_strategy).to receive(:call)

      expect(deactivation_strategy).to receive(:call).with(customer_bonus)

      customer_bonus.close!(deactivation_strategy)
    end

    describe '#expired?' do
      it 'returns false for active bonus' do
        customer_bonus = create(:customer_bonus)
        expect(customer_bonus.expired?).to be_falsey
      end

      it 'returns true for deleted bonus' do
        customer_bonus = create(:customer_bonus, deleted_at: Time.zone.now)
        expect(customer_bonus.expired?).to be_truthy
      end

      it 'returns true for expired bonus' do
        customer_bonus = create(
          :customer_bonus,
          valid_for_days: 1,
          created_at: Time.zone.now - 2.days
        )
        expect(customer_bonus.expired?).to be_truthy
      end
    end

    describe '#status' do
      it 'returns \'active\' for active bonus' do
        customer_bonus = create(:customer_bonus)
        expect(customer_bonus.status).to eq('active')
      end

      it 'returns \'expired\' for deleted bonus' do
        customer_bonus = create(:customer_bonus, deleted_at: Time.zone.now)
        expect(customer_bonus.status).to eq('expired')
      end

      it 'returns \'expired\' for expired bonus' do
        customer_bonus = create(
          :customer_bonus,
          valid_for_days: 1,
          created_at: Time.zone.now - 2.days
        )
        expect(customer_bonus.status).to eq('expired')
      end
    end

    describe '.customer_history' do
      let!(:customer) { create(:customer) }
      let!(:expired_customer_bonus) do
        create(:customer_bonus, customer: customer, deleted_at: Time.zone.now)
      end
      let!(:active_customer_bonus) do
        create(:customer_bonus, customer: customer)
      end

      it 'returns all customer activated bonuses' do
        expect(described_class.customer_history(customer))
          .to match_array([
                            active_customer_bonus,
                            expired_customer_bonus
                          ])
      end
    end
  end
end
