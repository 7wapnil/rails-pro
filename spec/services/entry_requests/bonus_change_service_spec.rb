# frozen_string_literal: true

describe EntryRequests::BonusChangeService do
  subject { described_class.call(entry_request: entry_request) }

  let(:customer) { create(:customer) }
  let(:currency) { create(:currency) }
  let(:rule) { create(:entry_currency_rule, min_amount: 0, max_amount: 500) }
  let(:amount) { 200 }
  let(:wallet) do
    create(:wallet, :empty, customer: customer, currency: currency)
  end
  let(:customer_bonus) do
    create(:customer_bonus, :initial, customer: customer, wallet: wallet)
  end
  let(:admin) { create(:user) }
  let(:entry_request) do
    EntryRequests::Factories::BonusChange.call(
      customer_bonus: customer_bonus,
      amount: amount,
      initiator: admin
    )
  end

  before do
    allow(EntryCurrencyRule).to receive(:find_by!) { rule }
    allow(Currency).to receive(:find_by!) { currency }
  end

  it 'creates entry request' do
    expect { subject }.to change(EntryRequest, :count).by(1)
  end

  it 'creates entry' do
    expect { subject }.to change(Entry, :count).by(1)
  end

  context 'changes wallet amount' do
    before do
      subject
      wallet.reload
    end

    it 'increases wallet amount' do
      expect(wallet.amount).to eq(200)
    end

    it 'increases bonus money balance amount' do
      expect(wallet.bonus_balance).to eq(200)
    end

    it 'does not affect real money balance amount' do
      expect(wallet.real_money_balance).to be_zero
    end
  end

  context 'with failed entry request' do
    before { entry_request.failed! }

    it 'does not proceed' do
      expect { subject }.to raise_error(
        EntryRequests::FailedEntryRequestError,
        I18n.t('errors.messages.bonuses.failed_authorization')
      )
    end
  end
end
