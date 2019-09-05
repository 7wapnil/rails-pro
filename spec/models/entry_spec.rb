describe Entry do
  subject { build(:entry, wallet: wallet, kind: rule.kind, amount: 50) }

  let(:currency) { create(:currency) }
  let(:rule) do
    create(:entry_currency_rule,
           currency: currency,
           min_amount: 10,
           max_amount: 100)
  end
  let(:wallet) { create(:wallet, currency: currency) }

  it { is_expected.to belong_to(:wallet) }
  it { is_expected.to belong_to(:origin) }
  it { is_expected.to belong_to(:entry_request) }
  it { is_expected.to belong_to(:customer_transaction) }
  it { is_expected.to belong_to(:withdrawal) }
  it { is_expected.to have_one(:currency) }
  it { is_expected.to have_many(:balance_entries) }

  it { is_expected.to validate_presence_of(:amount) }
  it { is_expected.to respond_to(:external_id) }

  context 'costomer_transaction association' do
    before do
      subject.origin = create(:deposit)
    end

    it 'has customer_transaction association' do
      expect(subject.customer_transaction).not_to be_nil
    end

    it 'does not have withdrawal association' do
      expect(subject.withdrawal).to be_nil
    end
  end

  include_examples 'precionable up to 12 digit', :amount
  include_examples 'precionable up to 12 digit', :balance_amount_after
end
