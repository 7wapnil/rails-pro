class DocumentsController < ApplicationController
  include Commentable

  def index
    @documents = documents_base_query
  end

  def show
    @document = VerificationDocument.find(document_id)
    @comments = @document.comments.order(:created_at)
  end

  def status
    doc = VerificationDocument.find(document_id)
    doc.update(status: document_status_code)
    current_user.log_event :document_status_updated, doc, doc.customer

    redirect_back(fallback_location: root_path)
  end

  private

  def documents_base_query
    return VerificationDocument.auctioned if params[:tab] == 'auctioned'

    VerificationDocument.pending
  end

  def document_id
    params.require(:id)
  end

  def document_status_code
    params.require(:status)
  end

  def resource_name
    VerificationDocument
  end
end
