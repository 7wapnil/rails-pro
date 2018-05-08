describe ScopedEvent, type: :model do
  it { should belong_to(:event_scope) }
  it { should belong_to(:event) }
end
