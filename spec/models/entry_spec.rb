describe Entry do
  let(:currency) { create(:currency) }
  let(:rule) do
    create(:entry_currency_rule,
           currency: currency,
           min_amount: 10,
           max_amount: 100)
  end
  let(:wallet) { create(:wallet, currency: currency) }

  subject { build(:entry, wallet: wallet, kind: rule.kind, amount: 50) }

  it { is_expected.to define_enum_for :kind }

  it { should belong_to(:wallet) }
  it { should belong_to(:origin) }
  it { should have_one(:currency) }
  it { should have_many(:balance_entries) }

  it { should validate_presence_of(:amount) }
end
