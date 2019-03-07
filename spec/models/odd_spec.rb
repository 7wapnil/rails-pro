describe Odd do
  subject(:odd) { described_class.new }

  it { is_expected.to belong_to(:market) }

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:status) }
  it { is_expected.to validate_numericality_of(:value).is_greater_than(0) }

  it 'validates value on create is status active' do
    odd.status = Odd::ACTIVE
    expect(odd).to validate_presence_of(:value).on(:create)
  end

  it 'not validates value on create if status inactive' do
    odd.status = Odd::INACTIVE
    expect(odd).not_to validate_presence_of(:value).on(:create)
  end
end
