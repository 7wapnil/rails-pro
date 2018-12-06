module CustomersHelper
  def attachment_for(customer, kind)
    customer
      .verification_documents
      .where(kind: kind)
      .order(created_at: :desc)
      .first
  end

  def allowed_account_kind_options(customer)
    allowed_kinds = if customer.regular?
                      Customer.account_kinds.keys
                    else
                      [customer.account_kind]
                    end

    options_for_select(allowed_kinds, customer.account_kind)
  end
end
