describe Discipline, type: :model do
  kinds = described_class::KINDS.values

  it { should have_many(:events) }

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:kind) }

  it { should validate_inclusion_of(:kind).in_array(kinds) }
end
