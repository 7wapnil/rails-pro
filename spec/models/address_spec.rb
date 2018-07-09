describe Address do
  it_should_behave_like 'audit model', factory: :address

  it { should belong_to(:customer) }
end
