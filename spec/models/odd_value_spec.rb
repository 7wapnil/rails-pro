describe OddValue, type: :model do
  it { should belong_to(:odd) }

  it { should validate_presence_of(:value) }
end
