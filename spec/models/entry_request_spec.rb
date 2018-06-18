describe EntryRequest do
  it { should belong_to(:customer) }
  it { should belong_to(:currency) }
    it { should belong_to(:origin) }

  it { should define_enum_for :status }
  it { should define_enum_for :kind }
  it { should validate_presence_of(:amount) }
  it { should validate_presence_of(:kind) }
end
