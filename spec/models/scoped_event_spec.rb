describe ScopedEvent do
  it { is_expected.to belong_to(:event_scope) }
  it { is_expected.to belong_to(:event) }

  it_behaves_like 'updatable on duplicate'
end
