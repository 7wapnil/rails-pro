describe EntryRequestPayload do
  subject { described_class.new(attributes_for(:entry_request_payload)) }

  it { should validate_presence_of(:customer) }
  it { should validate_presence_of(:kind) }
  it { should validate_presence_of(:amount) }
  it { should validate_presence_of(:currency) }

  it { should validate_numericality_of(:amount) }

  it { should validate_inclusion_of(:kind).in_array(described_class::KINDS) }
  it { should validate_inclusion_of(:currency).in_array(Wallet.currencies.keys) }
end
