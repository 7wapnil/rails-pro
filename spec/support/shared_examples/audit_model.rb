RSpec.shared_examples 'audit model' do |factory:|
  it 'should log event created' do
    target = build(factory)
    target.origin_kind = :user
    target.origin_id = 1
    expect(target).to receive(:log_event).with(:created, any_args)
    target.save
  end

  it 'should log event updated' do
    target = create(factory)
    target.origin_kind = :user
    target.origin_id = 1
    expect(target).to receive(:log_event).with(:updated, any_args)
    target.save
  end

  it 'should log event destroyed' do
    target = create(factory)
    target.origin_kind = :user
    target.origin_id = 1
    expect(target).to receive(:log_event).with(:destroyed, any_args)
    target.destroy
  end
end
