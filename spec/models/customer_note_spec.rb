describe CustomerNote do
  it_should_behave_like 'audit model', factory: :customer_note

  it { should belong_to(:user) }
  it { should belong_to(:customer) }

  it { should validate_presence_of(:content) }

  it { should act_as_paranoid }
end
