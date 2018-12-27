describe MarketTemplate do
  it { is_expected.to validate_presence_of(:external_id) }
  it { is_expected.to validate_presence_of(:name) }
end
