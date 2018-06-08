describe Wallet do
  it { should belong_to(:customer) }
  it { should belong_to(:currency) }
  it { should have_many(:balances) }
  it { should have_many(:entries) }

  it { should delegate_method(:code).to(:currency).with_prefix }
end
