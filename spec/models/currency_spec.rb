describe Currency do
  it { should have_many(:entry_currency_rules) }

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:code) }
end
