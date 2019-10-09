# frozen_string_literal: true

describe GraphQL, '#transactions' do
  let(:context) { { current_customer: customer } }
  let(:variables) { {} }
  let!(:customer) { create(:customer) }
  let!(:withdrawals) do
    create_list(:entry_request,
                5,
                customer: customer,
                origin_type: 'CustomerTransaction',
                kind: EntryRequest::WITHDRAW)
  end

  let!(:deposits) do
    create_list(:entry_request,
                5,
                customer: customer,
                origin_type: 'CustomerTransaction',
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
            customerId
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
    let(:query) do
      %(query transactions($filter: TransactionKind,
                           $perPage: Int!,
                           $page: Int!) {
          transactions(filter: $filter, perPage: $perPage, page: $page) {
            pagination {
              items
            }
            collection {
              id
            }
          }
        })
    end
    let(:variables) { { filter: filter, perPage: 10, page: 1 } }

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
      let(:filter) { nil }

      it 'returns all entry request' do
        expect(result['data']['transactions']['collection'].length)
          .to eq(withdrawals.length + deposits.length)
      end

      it 'includes pagination param - items' do
        expect(result['data']['transactions']['pagination']['items'])
          .to eq(withdrawals.length + deposits.length)
      end
    end

    context 'query with no filter' do
      let(:variables) { { perPage: 10, page: 1 } }

      it 'returns all entry request' do
        expect(result['data']['transactions']['collection'].length)
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
