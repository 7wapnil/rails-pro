describe Event, type: :model do
  kinds = described_class::KINDS.values

  it { should belong_to(:discipline) }
  it { should belong_to(:event) }
  it { should have_many(:markets) }

  it { should validate_presence_of(:kind) }
  it { should validate_presence_of(:name) }

  it { should validate_inclusion_of(:kind).in_array(kinds) }
end
