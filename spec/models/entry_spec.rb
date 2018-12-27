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

  # it { should define_enum_for(:kind) }

  it { is_expected.to belong_to(:wallet) }
  it { is_expected.to belong_to(:origin) }
  it { is_expected.to have_one(:currency) }
  it { is_expected.to have_many(:balance_entries) }

  it { is_expected.to validate_presence_of(:amount) }
end
