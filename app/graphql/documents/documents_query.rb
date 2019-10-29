module Documents
  class DocumentsQuery < ::Base::Resolver
    type !types[DocumentType]

    description 'Get uploaded documents'
    mark_as_trackable

    def resolve(_obj, _args)
      VerificationDocument
        .select('DISTINCT ON (kind) *')
        .where(customer: @current_customer)
        .order(kind: :asc, created_at: :desc)
        .all
    end
  end
end
