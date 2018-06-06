describe ScopedEvent do
  it { should belong_to(:event_scope) }
  it { should belong_to(:event) }
end
