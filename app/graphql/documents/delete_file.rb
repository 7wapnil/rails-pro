module Documents
  class DeleteFile < ::Base::Resolver
    argument :id, !types.ID

    type !types.Boolean

    description 'Delete document file'

    def resolve(_obj, args)
      VerificationDocument.find_by!(id: args[:id]).destroy
      true
    end
  end
end
