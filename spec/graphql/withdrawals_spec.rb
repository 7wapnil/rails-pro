# frozen_string_literal: true

describe GraphQL, '#withdrawals' do
  let(:context) { { current_customer: customer } }
  let(:variables) { {} }
  let!(:customer) { create(:customer) }
  let!(:withdrawals) do
    create_list(:entry_request,
                5,
                customer: customer,
                kind: EntryRequest::WITHDRAW)
  end

  let(:withdrawal) { withdrawals.sort_by(&:created_at).reverse.first }

  let(:query) do
    %({
        withdrawals {
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

  # TODO: uncomment after shared example fix
  # it_behaves_like Base::Pagination do
  #   let(:paginated_collection) { withdrawals }
  #   let(:pagination_query) { query }
  #   let(:pagination_variables) { variables }
  #   let(:pagination_context) { context }
  # end

  context 'basic query' do
    before do
      create_list(:entry_request, 5, customer: customer)
    end

    it 'returns correctly first entry request' do
      expect(result['data']['withdrawals']['collection'][0]['id'])
        .to eq(withdrawal.id.to_s)
    end

    it 'includes pagination param - items' do
      expect(result['data']['withdrawals']['pagination']['items'])
        .to eq(withdrawals.length)
    end
  end
end
