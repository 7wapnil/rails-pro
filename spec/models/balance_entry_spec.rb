describe BalanceEntry do
  it { should belong_to(:balance) }
  it { should belong_to(:entry) }

  it { should validate_presence_of(:amount) }
end
