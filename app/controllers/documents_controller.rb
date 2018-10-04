class DocumentsController < ApplicationController
  def show; end

  def index
    @documents = VerificationDocument
                 .where(status: 'pending')
  end

  def update_document_status
    VerificationDocument
      .find(document_id)
      .update(status: document_status_code)
    redirect_to documents_path
  end

  private

  def document_id
    params.require(:document_id)
  end

  def document_status_code
    params.require(:status)
  end
end
