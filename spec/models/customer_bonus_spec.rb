# frozen_string_literal: true

describe CustomerBonus do
  it { is_expected.to belong_to(:customer) }
  it { is_expected.to belong_to(:wallet) }
  it { is_expected.to belong_to(:original_bonus) }
  it { is_expected.to belong_to(:balance_entry).inverse_of(:customer_bonus) }
  it { is_expected.to have_many(:bets) }
  it { is_expected.to have_one(:entry).through(:balance_entry) }
  it { is_expected.to have_one(:currency).through(:wallet) }

  describe '.customer_history' do
    let(:wallet) { create(:wallet) }
    let(:customer_bonus) do
      create(:customer_bonus, wallet: wallet, customer: wallet.customer)
    end
    let!(:customer) { create(:customer) }
    let!(:expired_customer_bonus) do
      create(:customer_bonus, customer: customer)
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

  describe '#time_exceeded?' do
    it 'is false when is not active' do
      sample_status =
        CustomerBonus::STATUSES.values.without(CustomerBonus::ACTIVE).sample

      customer_bonus = build(
        :customer_bonus,
        status: sample_status
      )

      expect(customer_bonus.time_exceeded?).to be false
    end

    it 'is false when activated_at is not present' do
      customer_bonus = build(
        :customer_bonus,
        status: CustomerBonus::ACTIVE,
        activated_at: nil
      )

      expect(customer_bonus.time_exceeded?).to be false
    end

    it 'is false when due date is in future' do
      customer_bonus = build(
        :customer_bonus,
        activated_at: 3.days.ago,
        valid_for_days: 4
      )

      expect(customer_bonus.time_exceeded?).to be false
    end

    it 'is true when due date is today' do
      customer_bonus = build(
        :customer_bonus,
        activated_at: 3.days.ago,
        valid_for_days: 3
      )

      expect(customer_bonus.time_exceeded?).to be true
    end

    it 'is true when due date is in past' do
      customer_bonus = build(
        :customer_bonus,
        activated_at: 4.days.ago,
        valid_for_days: 3
      )

      expect(customer_bonus.time_exceeded?).to be true
    end
  end

  context 'state transition timestamps' do
    before { subject }

    describe '#activate!' do
      subject { customer_bonus.activate!(nil) }

      let(:customer_bonus) do
        create(:customer_bonus, status: CustomerBonus::INITIAL)
      end

      it 'sets #activated_at' do
        expect(customer_bonus.reload.activated_at).not_to be_nil
      end
    end
  end

  describe 'dectivation' do
    before { subject }

    let(:customer_bonus) do
      create(:customer_bonus, status: CustomerBonus::ACTIVE)
    end

    context '#cancel!' do
      subject { customer_bonus.cancel! }

      it 'sets #deactivated_at' do
        expect(customer_bonus.reload.deactivated_at).not_to be_nil
      end
    end

    context '#expire!' do
      subject { customer_bonus.expire! }

      it 'sets #deactivated_at' do
        expect(customer_bonus.reload.deactivated_at).not_to be_nil
      end
    end

    context '#lose!' do
      subject { customer_bonus.lose! }

      it 'sets #deactivated_at' do
        expect(customer_bonus.reload.deactivated_at).not_to be_nil
      end
    end
  end

  describe '#locked?' do
    let(:customer_bonus) do
      create(:customer_bonus, status: CustomerBonus::ACTIVE)
    end
    let(:bet) do
      create(
        :bet,
        customer_bonus: customer_bonus,
        status: bet_status
      )
    end

    context 'with pending bet' do
      let(:bet_status) { StateMachines::BetStateMachine::ACCEPTED }

      it 'returns true' do
        bet
        expect(customer_bonus).to be_locked
      end
    end

    context 'without pending bets' do
      let(:bet_status) { StateMachines::BetStateMachine::SETTLED }

      it 'returns false' do
        bet
        expect(customer_bonus).not_to be_locked
      end
    end
  end
end
