describe Wallet do
  it { should belong_to(:customer) }
  it { should belong_to(:currency) }
  it { should have_many(:balances) }
  it { should have_many(:entries) }
end
