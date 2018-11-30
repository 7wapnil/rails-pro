module DocumentsHelper
  def kind_options
    mapped_kinds = VerificationDocument::KINDS.map do |key, value|
      [key.to_s.humanize, value]
    end

    [mapped_kinds, query_params[:kind_eq]]
  end

  def status_options
    statuses = VerificationDocument.statuses.slice(:rejected, :confirmed)
    mapped_statuses = statuses.map do |key, value|
      [key.humanize, value]
    end

    [mapped_statuses, query_params[:status_eq]]
  end
end
