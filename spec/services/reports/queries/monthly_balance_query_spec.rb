# frozen_string_literal: true

describe ::Reports::Queries::MonthlyBalanceQuery do
  subject { described_class }

  it 'creates new result record' do
    expect { subject.call }.to change(MonthlyBalanceQueryResult, :count).by(1)
  end
end
