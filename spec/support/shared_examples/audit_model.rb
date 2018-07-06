RSpec.shared_examples 'audit model' do |factory:|
  it 'should log event created' do
    target = build(factory)
    expect(target).to receive(:log_event).with(:created)
    target.save
  end

  it 'should log event updated' do
    target = create(factory)
    expect(target).to receive(:log_event).with(:updated)
    target.save
  end

  it 'should log event destroyed' do
    target = create(factory)
    expect(target).to receive(:log_event).with(:destroyed)
    target.destroy
  end
end
