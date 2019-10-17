# frozen_string_literal: true

describe GraphQL, '#everyMatrixTransactions' do
  let(:context) { { current_customer: customer } }
  let(:variables) { {} }
  let!(:customer) { create(:customer) }

  let(:query) do
    %({
        everyMatrixTransactions() {
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
            amount
            currencyCode
            type
            transactionId
            gameName
            vendorName
            createdAt
          }
        }
      })
  end

  let(:result) do
    ArcanebetSchema.execute(query, context: context, variables: variables)
  end

  context 'basic query' do
    let!(:transactions) do
      create_list(:every_matrix_transaction, 10, customer: customer)
    end

    it 'returns correct response' do
      expect(
        result
          .dig('data', 'everyMatrixTransactions', 'collection')
          .first['transactionId']
      ).to eq(transactions.last.transaction_id.to_s)
    end
  end
end
