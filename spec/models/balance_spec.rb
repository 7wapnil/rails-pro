describe Balance, type: :model do
  it { should belong_to(:wallet) }
  it { should have_many(:balance_entries) }
end
