# frozen_string_literal: true

describe Customers::Statistic, type: :model do
  subject { build(:customer_statistic) }

  it { is_expected.to belong_to(:customer) }

  it 'table_name is changed' do
    expect(described_class.table_name).to eq('customer_statistics')
  end
end
