class CustomerAttachmentController < ApiController
  protect_from_forgery with: :null_session

  respond_to :json

  def customer_attachment_upload
    attachments_from_params.each do |attachment_type, file|
      current_customer.send("#{attachment_type}=", file)
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
