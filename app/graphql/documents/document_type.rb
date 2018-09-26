module Documents
  DocumentType = GraphQL::ObjectType.define do
    name 'Document'

    field :id, !types.ID
    field :status, !types.String
    field :kind, !types.String
    field :filename, !types.String, 'Name of attachment file' do
      resolve ->(obj, _args, _ctx) { obj.document.filename }
    end
  end
end
