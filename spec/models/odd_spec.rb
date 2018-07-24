describe Odd do
  it { should belong_to(:market) }

  it { should validate_presence_of(:name) }
end
