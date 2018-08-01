describe Market do
  it { should define_enum_for(:status) }

  it { should belong_to(:event) }
  it { should have_many(:odds) }

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:priority) }
  it { should validate_presence_of(:status) }
end
