describe AuditLog do
  it { should validate_presence_of(:event) }

  it 'stores in logs db' do
    customer = create(:customer)
    AuditLog.create!(event: 'test.event',
                     customer_id: customer.id)
  end
end
