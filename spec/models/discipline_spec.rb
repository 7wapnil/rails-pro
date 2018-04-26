describe Discipline, type: :model do
  it { is_expected.to(validate_presence_of(:name)) }
  it { is_expected.to(validate_presence_of(:kind)) }

  it do
    is_expected.to(
      validate_inclusion_of(:kind).in_array(described_class::KINDS.values)
    )
  end
end
