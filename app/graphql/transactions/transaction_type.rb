module Transactions
  TransactionType = GraphQL::ObjectType.define do
    name 'Transactions'

    field :id, !types.ID
    field :customerId, types.ID, property: :customer_id
    field :status, types.String,
          resolve: ->(obj, _args, _ctx) do
            return obj.status if obj.refund?

            obj.origin&.status || obj.status
          end
    field :mode, types.String,
          resolve: ->(obj, _args, _ctx) do
            mode = obj.refund? ? EntryRequest::REFUND : obj.mode
            I18n.t("payments.payment_methods.#{mode}",
                   default: mode.humanize)
          end
    field :currencyCode, types.String,
          resolve: ->(obj, _args, _ctx) { obj.currency.code }
    field :amount, types.Float
    field :comment, types.String
    field :createdAt, types.String do
      resolve ->(obj, _args, _ctx) { obj.created_at.strftime('%e.%m.%y') }
    end
    field :updatedAt, types.String do
      resolve ->(obj, _args, _ctx) { obj.updated_at.strftime('%e.%m.%y') }
    end
  end
end
