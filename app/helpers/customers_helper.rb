module CustomersHelper
  def attachment_for(customer, kind)
    customer
      .verification_documents
      .where(kind: kind)
      .order(created_at: :desc)
      .first
  end
end
