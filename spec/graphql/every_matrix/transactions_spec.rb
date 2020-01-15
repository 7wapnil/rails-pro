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
            userId
            debit
            credit
            balance
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
    context 'with current transactions' do
      let!(:transactions) do
        create_list(:every_matrix_transaction, 10, :wager, customer: customer)
      end

      it 'returns correct number of items' do
        expect(
          result
            .dig('data', 'everyMatrixTransactions', 'collection')
            .size
        ).to eq(transactions.size)
      end
    end

    context 'with current and old transactions' do
      let!(:current_transactions) do
        create_list(:every_matrix_transaction, 5, :wager, customer: customer)
      end
      let!(:old_transactions) do
        create_list(
          :every_matrix_transaction,
          5,
          :wager,
          customer: customer,
          created_at: EveryMatrix::TransactionsQuery::HISTORY_DAYS.days.ago
        )
      end

      it 'returns correct number of items' do
        expect(
          result
            .dig('data', 'everyMatrixTransactions', 'collection')
            .size
        ).to eq(current_transactions.size)
      end
    end
  end
end
