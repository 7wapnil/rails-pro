describe Deposits::DepositLimitCheckService do
  describe '.call' do
    include_context 'frozen_time'

    subject(:service_call) { described_class.call(wallet, deposit_amount) }

    let(:deposit_amount) { Faker::Number.number(2).to_i }

    let(:deposit_limit) do
      create(:deposit_limit, value: deposit_amount + 100)
    end
    let(:customer) { deposit_limit.customer }
    let(:wallet) do
      create(:wallet, customer: customer, currency: deposit_limit.currency)
    end

    let(:a_little) { 0.01 }
    let(:a_little_time) { 1.second }

    let(:last_limit_range_included_datetime) do
      Time.current - deposit_limit.range.days
    end
    let(:max_existing_deposits_volume) do
      deposit_limit.value - deposit_amount
    end
    let(:over_deposit_limit) do
      max_existing_deposits_volume + a_little
    end

    let(:limit_influence_entry_request_states) do
      [EntryRequest::SUCCEEDED, EntryRequest::PENDING]
    end

    let(:limit_influence_entry_request_state) do
      limit_influence_entry_request_states.sample
    end

    let(:under_limit_attributes) do
      {
        customer: customer,
        kind: EntryRequest::DEPOSIT,
        status: limit_influence_entry_request_state,
        created_at: last_limit_range_included_datetime,
        amount: max_existing_deposits_volume - a_little
      }
    end

    context 'when wallet has no deposit limits' do
      let(:wallet) { create(:wallet) }

      it 'returns true' do
        expect(described_class.call(wallet, deposit_amount)).to be_truthy
      end
    end

    context 'when volume is under limit' do
      before { create(:entry_request, &under_limit_attributes) }

      it 'returns false' do
        expect(service_call).to be_truthy
      end
    end

    context 'when over limit deposits volume' do
      before do
        create(:entry_request,
               under_limit_attributes
                 .merge(amount: over_deposit_limit))
      end

      it 'returns false' do
        expect(service_call).to be_falsey
      end
    end

    context 'when too big volume of different requests' do
      before do
        create(:entry_request,
               under_limit_attributes
                 .merge(
                   status: EntryRequest::PENDING,
                   amount: max_existing_deposits_volume / 2 + a_little
                 ))
        create(:entry_request,
               under_limit_attributes
                 .merge(
                   status: EntryRequest::SUCCEEDED,
                   amount: max_existing_deposits_volume / 2
                 ))
      end

      it 'returns false' do
        expect(service_call).to be_falsey
      end
    end

    context 'when too big volume of old requests' do
      before do
        create(:entry_request,
               under_limit_attributes
                 .merge(
                   created_at:
                     last_limit_range_included_datetime - a_little_time,
                   amount: over_deposit_limit
                 ))
      end

      it 'returns true' do
        expect(service_call).to be_truthy
      end
    end

    context 'when too big volume of different type requests' do
      before do
        create(:entry_request,
               under_limit_attributes
                 .merge(
                   kind: EntryRequest::WITHDRAW,
                   amount: over_deposit_limit
                 ))
      end

      it 'returns true' do
        expect(service_call).to be_truthy
      end
    end
  end
end
