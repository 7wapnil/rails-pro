describe BettingLimit do
  it { should belong_to(:customer) }
  it { should belong_to(:title) }

  it { should validate_presence_of(:customer) }
end
