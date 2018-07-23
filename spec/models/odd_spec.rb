describe Odd do
  it { should belong_to(:market) }
  it { should have_many(:odd_values) }

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:value) }
end
