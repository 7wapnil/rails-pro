class CustomerAttachmentController < ApiController
  protect_from_forgery with: :null_session

  respond_to :json

  def customer_attachment_upload
    return fail_with_no_customer_found unless current_customer
    return fail_with_no_documents_permitted if attachments_from_params.empty?

    Rails.logger.debug("Uploading attachments for customer #{current_customer}")
    Rails.logger.debug("received attachments #{attachments_from_params.keys}")

    attachments_from_params.each do |attachment_type, file|
      current_customer.send(attachment_type).attach(file)
    end

    render json: { success: true }
  end

  private

  def fail_with_no_customer_found
    error_msg = 'Customer not found from token'
    fail_with(error_msg)
  end

  def fail_with_no_documents_permitted
    error_msg = 'No documents permitted'
    fail_with(error_msg)
  end

  def fail_with(message, status: 400)
    render(json: { success: false, status: status, errors: [message] })
  end

  def attachments_from_params
    params
      .require(:attachments)
      .permit(*Customer::ATTACHMENT_TYPES)
  end
end
