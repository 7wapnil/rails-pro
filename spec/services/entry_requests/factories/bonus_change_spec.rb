# frozen_string_literal: true

describe EntryRequests::Factories::BonusChange do
  subject { described_class.call(params) }

  let(:params) do
    {
      customer_bonus: customer_bonus,
      amount: amount,
      initiator: admin
    }
  end

  let(:customer) { create(:customer) }
  let(:wallet) { create(:wallet, customer: customer) }
  let(:customer_bonus) do
    create(:customer_bonus, customer: customer, wallet: wallet)
  end
  let(:amount) { rand(100.0).to_d }
  let(:rule) { create(:entry_currency_rule, min_amount: 0, max_amount: 500) }
  let(:admin) { create(:user) }
  let(:comment) do
    "Bonus transaction: #{amount} #{customer_bonus.currency} " \
    "for #{customer} by #{admin}."
  end

  before do
    allow(EntryCurrencyRule).to receive(:find_by!) { rule }
    allow(Currency).to receive(:find_by!) { customer_bonus.currency }
  end

  it 'creates entry request' do
    expect { subject }.to change(EntryRequest, :count).by(1)
  end

  it 'creates bonus balance entry request' do
    expect { subject }.to change(BalanceEntryRequest, :count).by(1)
  end

  it 'returns entry request with valid attributes' do
    expect(subject).to have_attributes(
      amount: amount,
      mode: EntryRequest::INTERNAL,
      kind: EntryRequest::BONUS_CHANGE,
      initiator: admin,
      comment: comment,
      origin: customer_bonus,
      currency: customer_bonus.currency,
      customer: customer
    )
  end

  it 'creates balance entry request with valid attributes' do
    expect(subject.bonus_balance_entry_request).to have_attributes(
      amount: amount,
      kind: Balance::BONUS
    )
  end

  context 'when initiator is not passed' do
    let(:admin) {}
    let(:comment) do
      "Bonus transaction: #{amount} #{customer_bonus.currency} for #{customer}."
    end

    it 'shortens entry request comment' do
      expect(subject.comment).to eq(comment)
    end
  end

  context 'when expired customer bonus is passed' do
    let(:customer_bonus) do
      create(:customer_bonus, :expired, customer: customer, wallet: wallet)
    end

    it 'returns failed entry request' do
      expect(subject).to have_attributes(
        status: EntryRequest::FAILED,
        result: {
          'message' => I18n.t('errors.messages.entry_requests.bonus_expired')
        }
      )
    end
  end
end
