RSpec.shared_examples 'callable service' do |_parameter|
  it 'is callable with one argument' do
    expect(described_class).to respond_to(:call).with(1).argument
  end

  it 'responds to call method' do
    expect(described_class.new(double))
      .to respond_to(:call).with(0).argument
  end

  it 'passes #call to instance method .call' do
    arguments = double

    expect(described_class)
      .to receive(:new)
      .with(arguments)
      .and_call_original

    expect_any_instance_of(described_class).to receive(:call)

    described_class.call(arguments)
  end
end
