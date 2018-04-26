describe Event, type: :model do
  it { should belong_to(:discipline) }
  it { should belong_to(:event) }
  it { should have_many(:markets) }

  it { should validate_presence_of(:kind) }
  it { should validate_presence_of(:name) }
end
