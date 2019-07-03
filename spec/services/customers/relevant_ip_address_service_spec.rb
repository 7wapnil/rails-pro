describe Customers::RelevantIpAddressService do
  it 'returns current sign in ip' do
    customer = build(:customer)
    expect(described_class.call(customer)).to eq customer.current_sign_in_ip
  end

  it 'returns last sign in ip' do
    customer = build(:customer, current_sign_in_ip: nil)
    expect(described_class.call(customer)).to eq customer.last_sign_in_ip
  end

  it 'returns nil' do
    customer = build(:customer, current_sign_in_ip: nil, last_sign_in_ip: nil)
    expect(described_class.call(customer)).to be_nil
  end
end
