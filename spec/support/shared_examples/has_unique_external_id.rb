shared_examples 'has unique :external_id' do
  it { should validate_uniqueness_of(:external_id) }
end
