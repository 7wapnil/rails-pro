describe Address, type: :model do
  it { should belong_to(:customer) }
end
