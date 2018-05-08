describe Discipline, type: :model do
  it { should have_many(:events) }
  it { should have_many(:event_scopes) }

  it { should define_enum_for(:kind) }

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:kind) }
end
