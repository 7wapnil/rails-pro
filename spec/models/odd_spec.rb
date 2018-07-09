describe Odd do
  it_should_behave_like 'audit model', factory: :odd

  it { should belong_to(:market) }
  it { should have_many(:odd_values) }

  it { should validate_presence_of(:name) }
end
