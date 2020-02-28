describe Affiliates::Import do
  let(:import_file) { file_fixture('affiliates_import.csv') }

  before { described_class.call(import_file) }

  it 'creates affiliates from uploaded input' do
    expect(Affiliate.count).to eq 5
  end

  it 'overwrites existing affiliate details' do
    affiliate = Affiliate.find_by(name: 'onlinecasinohunters')
    affiliate.update(sports_revenue_share: 20)

    expect { described_class.call(import_file) }
      .to change { affiliate.reload.sports_revenue_share }
      .from(20)
      .to(45)
  end

  it 'ignores affiliates that haven\'t changed' do
    affiliate = Affiliate.take

    expect { described_class.call(import_file) }
      .not_to change { affiliate.reload.updated_at }
  end
end
