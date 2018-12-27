describe AuditLog do
  it { is_expected.to validate_presence_of(:event) }

  it 'stores in logs db' do
    customer = create(:customer)
    described_class.create!(event: 'test.event',
                            customer_id: customer.id)
  end
end
