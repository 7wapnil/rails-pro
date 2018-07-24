describe Odd do
  it { should belong_to(:market) }
  it { should have_many(:odd_values) }

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:value) }
  it { should validate_numericality_of(:value).is_greater_than(0) }
end
