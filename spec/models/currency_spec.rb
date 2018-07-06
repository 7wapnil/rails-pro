describe Currency do
  it_should_behave_like 'audit model', factory: :currency
  it { should have_many(:entry_currency_rules) }

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:code) }
end
