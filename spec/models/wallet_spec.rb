describe Wallet, type: :model do
  it { should belong_to(:customer) }
  it { should have_many(:balances) }
  it { should have_many(:entries) }
end
