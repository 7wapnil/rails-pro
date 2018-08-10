describe AuditLog do
  it { should validate_presence_of(:event) }
  it { should validate_presence_of(:origin_kind) }
  it { should validate_presence_of(:origin_id) }

  before do
    AuditLog.delete_all
  end

  it 'stores in logs db' do
    customer = create(:customer)
    AuditLog.create!(event: 'test.event',
                     origin_kind: :user,
                     origin_id: 1,
                     context: { id: customer.id,
                                updates: customer.previous_changes })
  end
end
