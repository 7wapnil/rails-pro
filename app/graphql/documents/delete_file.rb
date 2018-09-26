module Documents
  class DeleteFile < ::Base::Resolver
    argument :id, !types.ID

    type !types.Boolean

    def resolve(_obj, args)
      doc = VerificationDocument.find_by!(id: args[:id])
      doc.destroy
      true
    end
  end
end
