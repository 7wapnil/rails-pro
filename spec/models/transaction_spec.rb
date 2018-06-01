describe Transaction, type: :model do
  it { should belong_to(:wallet) }
end
