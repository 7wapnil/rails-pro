class CountryCollectionInput < SimpleForm::Inputs::CollectionSelectInput
  def input(_wrapper_options = nil)
    label_method = :to_s
    value_method = :to_s

    @builder.collection_select(
      attribute_name,
      collection,
      value_method,
      label_method,
      input_options,
      input_html_options.merge(class: 'form-control country-select')
    )
  end
end
