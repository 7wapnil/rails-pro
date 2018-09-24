module CustomersHelper
  def attachment_for(customer, kind)
    collection = customer
                 .verification_documents
                 .where(kind: kind)
                 .order(created_at: :desc)
    return collection.first if collection.any?
    OpenStruct.new(filename: t(:no_file))
  end
end
