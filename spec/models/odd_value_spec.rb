describe OddValue do
  it_should_behave_like 'audit model', factory: :odd_value

  it { should belong_to(:odd) }

  it { should validate_presence_of(:value) }
end
