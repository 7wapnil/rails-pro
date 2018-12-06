shared_examples 'updatable on duplicate' do
  it 'responds to create or update on duplicate call' do
    expect(described_class).to respond_to(:create_or_update_on_duplicate)
  end
end
