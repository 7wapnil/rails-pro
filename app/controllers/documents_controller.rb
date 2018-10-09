class DocumentsController < ApplicationController
  def index
    @documents = VerificationDocument
                 .where(status: :pending)
  end

  def status
    doc = VerificationDocument.find(document_id)
    doc.update(status: document_status_code)
    current_user.log_event :document_status_updated, doc, doc.customer

    redirect_back(fallback_location: root_path)
  end

  private

  def document_id
    params.require(:id)
  end

  def document_status_code
    params.require(:status)
  end
end
