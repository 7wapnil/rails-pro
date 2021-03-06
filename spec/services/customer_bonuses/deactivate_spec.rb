# frozen_string_literal: true

describe CustomerBonuses::Deactivate do
  let(:customer_bonus) { create(:customer_bonus) }

  include_context 'frozen_time'

  context 'with active customer bonus' do
    context 'with positive bonus balance' do
      let(:bonus_balance) { wallet.bonus_balance }
      let(:wallet) { customer_bonus.wallet }

      let(:found_entry_request) do
        EntryRequest.bonus_cancellation.find_by(origin: customer_bonus)
      end
      let(:comment) do
        "Bonus transaction: #{-bonus_balance} #{wallet.currency} " \
        "for #{wallet.customer}."
      end

      before do
        allow(EntryRequests::BonusChangeService).to receive(:call)
        described_class.call(
          bonus: customer_bonus,
          action: described_class::CANCEL
        )
      end

      it 'creates bonus change entry request' do
        expect(found_entry_request).to have_attributes(
          mode: EntryRequest::INTERNAL,
          amount: -bonus_balance,
          comment: comment,
          customer: wallet.customer,
          currency: wallet.currency
        )
      end

      it 'schedules job for updating wallet' do
        expect(EntryRequests::BonusChangeService)
          .to have_received(:call)
          .with(entry_request: found_entry_request)
      end
    end
  end

  context 'lose' do
    let :customer_bonus do
      create(:customer_bonus, :with_empty_bonus_balance)
    end

    let(:action) { described_class::LOSE }

    it 'sets custome bonus status to :lost' do
      expect { described_class.call(bonus: customer_bonus, action: action) }
        .to change(customer_bonus, :status)
        .from(CustomerBonus::ACTIVE)
        .to(CustomerBonus::LOST)
    end

    it 'doesn\'t schedule bonus funds confiscation' do
      expect(EntryRequests::BonusChangeService).not_to receive(:call)
      described_class.call(bonus: customer_bonus, action: action)
    end
  end

  context 'negative bonus balance' do
    subject do
      described_class.call(bonus: customer_bonus, action: action)
    end

    let(:bonus) { create(:bonus) }
    let(:currency) { create(:currency, :primary) }
    let(:wallet) do
      create(:wallet, currency: currency, bonus_balance: bonus_balance)
    end
    let(:customer_bonus) do
      create(:customer_bonus, original_bonus: bonus, wallet: wallet)
    end
    let(:bonus_balance) { -100 }

    before { subject }

    context 'lose' do
      let(:action) { described_class::LOSE }
      let(:loss_entry) { customer_bonus.loss_entry }

      it 'nullifies bonus balance' do
        expect(wallet.reload.bonus_balance).to be_zero
      end

      it 'creates entry with deducted amount' do
        expect(loss_entry.bonus_amount).to eq(-bonus_balance)
      end
    end
  end
end
