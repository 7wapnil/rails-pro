describe MarketTemplate do
  it { should validate_presence_of(:external_id) }
  it { should validate_presence_of(:name) }
end
