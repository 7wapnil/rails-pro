# frozen_string_literal: true

describe GraphQL, '#transactions' do
  let(:context) { { current_customer: customer } }
  let(:variables) { {} }
  let!(:customer) { create(:customer) }
  let!(:withdrawals) do
    create_list(:entry_request,
                5,
                customer: customer,
                kind: EntryRequest::WITHDRAW)
  end

  let!(:deposits) do
    create_list(:entry_request,
                5,
                customer: customer,
                kind: EntryRequest::DEPOSIT)
  end

  let(:withdrawal) { withdrawals.sort_by(&:created_at).reverse.first }
  let(:deposit) { deposits.sort_by(&:created_at).reverse.first }

  let(:query) do
    %({
        transactions(filter: #{filter}) {
          pagination {
            count
            items
            page
            pages
            offset
            last
            next
            prev
            from
            to
          }
          collection {
            id
            customer_id
            status
            mode
            currencyCode
            amount
            comment
          }
        }
      })
  end
  let(:result) do
    ArcanebetSchema.execute(query, context: context, variables: variables)
  end

  context 'basic query' do
    context 'withdraw' do
      let(:filter) { EntryKinds::WITHDRAW }

      it 'returns correctly first entry request with kind withdraw' do
        expect(result['data']['transactions']['collection'][0]['id'])
          .to eq(withdrawal.id.to_s)
      end

      it 'includes pagination param - items' do
        expect(result['data']['transactions']['pagination']['items'])
          .to eq(withdrawals.length)
      end
    end

    context 'deposit' do
      let(:filter) { EntryKinds::DEPOSIT }

      it 'returns correctly first entry request with kind deposit' do
        expect(result['data']['transactions']['collection'][0]['id'])
          .to eq(deposit.id.to_s)
      end

      it 'includes pagination param - items' do
        expect(result['data']['transactions']['pagination']['items'])
          .to eq(deposits.length)
      end
    end

    context 'all' do
      let(:filter) {}

      it 'returns all entry request' do
        expect(result['data']['transactions']['collection'].length)
          .to eq(withdrawals.length + deposits.length)
      end

      it 'includes pagination param - items' do
        expect(result['data']['transactions']['pagination']['items'])
          .to eq(withdrawals.length + deposits.length)
      end
    end
  end

  context 'pagination' do
    let(:filter) { EntryKinds::WITHDRAW }

    it_behaves_like Base::Pagination do
      let(:paginated_collection) { withdrawals.sort_by(&:created_at).reverse }
      let(:pagination_query) { query }
      let(:pagination_variables) { variables }
      let(:pagination_context) { context }
    end
  end
end
