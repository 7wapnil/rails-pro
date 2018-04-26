describe Market, type: :model do
  it { should belong_to(:event) }
  it { should have_many(:odds) }

  it { should validate_presence_of(:name) }
end
