shared_examples 'precionable up to 12 digit' do |field|
  it 'stores up to 12 digit, scale 2' do
    amount = 10**11 + 0.15
    instance = create(described_class.name.underscore)
    instance.update_attribute(field, amount)

    expect(instance.reload.send(field)).to eq(amount)
  end

  it 'filed on more than 12 digit, scale 2' do
    amount = 10**12 + 0.15
    instance = create(described_class.name.underscore)

    expect { instance.update_attribute(field, amount) }
      .to raise_error(ActiveRecord::RangeError)
  end
end
