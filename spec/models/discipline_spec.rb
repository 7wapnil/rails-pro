describe Discipline, type: :model do
  it { should have_many(:events) }

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:kind) }

  it { should validate_uniqueness_of(:name) }
end
