# frozen_string_literal: true

describe CustomerBonuses::Complete do
  subject { described_class.call(customer_bonus: customer_bonus) }

  context 'with a non-active bonus' do
    let(:customer_bonus) do
      create(:customer_bonus,
             status: CustomerBonus::EXPIRED)
    end

    before do
    end

    it 'does not complete the bonus' do
      subject
      expect(customer_bonus).not_to be_completed
    end

    it 'creates no new EntryRequests' do
      expect { subject }.not_to change(EntryRequest, :count)
    end
  end

  context 'with an active rolled over bonus' do
    let(:wallet) { create(:wallet) }
    let!(:currency) { create(:currency, :primary) }
    let(:customer_bonus) do
      create(:customer_bonus, wallet: wallet,
                              rollover_balance: 0)
    end
    let(:converted_amount) { wallet.bonus_balance }

    it 'completes the bonus' do
      subject
      expect(customer_bonus.reload).to be_completed
    end

    it 'sets total converted amount' do
      subject
      expect(customer_bonus.reload.total_converted_amount)
        .to eq(converted_amount)
    end

    it 'creates a bonus EntryRequest' do
      expect { subject }
        .to change(EntryRequest.where(kind: EntryKinds::BONUS_CHANGE), :count)
    end

    it 'creates a real_money EntryRequest' do
      expect { subject }
        .to change(
          EntryRequest.where(kind: EntryKinds::BONUS_CONVERSION), :count
        )
    end
  end
end
