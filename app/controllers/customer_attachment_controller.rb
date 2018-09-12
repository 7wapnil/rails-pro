class CustomerAttachmentController < ApiController
  protect_from_forgery with: :null_session

  respond_to :json

  def customer_attachment_upload # rubocop:disable Metrics/MethodLength
    error_msg = 'Customer not found from token'
    unless current_customer
      return render(json: { success: false, errors: [error_msg] })
    end

    Rails.logger.debug("Uploading attachments for customer #{current_customer}")
    Rails.logger.debug("received attachments #{params[:attachments].keys}")

    attachments_from_params.each do |attachment_type, file|
      current_customer.send(attachment_type).attach(file)
    end

    unless current_customer.valid?
      render(json: { success: false, errors: current_customer.errors })
      return
    end
    render json: { success: true }
  end

  private

  def attachments_from_params
    params
      .require(:attachments)
      .permit(*Customer::ATTACHMENT_TYPES)
  end
end
