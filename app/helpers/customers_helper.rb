module CustomersHelper
  def attachment_for(customer, attachment_type)
    collection = customer.send(attachment_type)
    return collection.last if collection.any?
    OpenStruct.new(filename: t(:no_file))
  end
end
