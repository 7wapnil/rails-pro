# frozen_string_literal: true

describe CustomerBonus do
  it { is_expected.to belong_to(:customer) }
  it { is_expected.to belong_to(:wallet) }
  it { is_expected.to belong_to(:original_bonus) }
  it { is_expected.to belong_to(:balance_entry).inverse_of(:customer_bonus) }
  it { is_expected.to have_many(:bets) }
  it { is_expected.to have_one(:entry).through(:balance_entry) }
  it { is_expected.to have_one(:currency).through(:wallet) }

  context 'instance methods' do
    let(:wallet) { create(:wallet) }
    let(:customer_bonus) do
      create(:customer_bonus, wallet: wallet, customer: wallet.customer)
    end

    describe '.customer_history' do
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
  end
end
