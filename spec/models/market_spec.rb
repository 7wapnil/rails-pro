describe Market do
  it_should_behave_like 'audit model', factory: :market

  it { should belong_to(:event) }
  it { should have_many(:odds) }

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:priority) }
end
