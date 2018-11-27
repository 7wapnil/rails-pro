class PhoneInput < SimpleForm::Inputs::Base
  def input(_wrapper_options = nil)
    @builder.phone_field(
      attribute_name,
      input_html_options.merge(
        class: 'form-control phone-input',
        data: { inputmask: '"mask": "+999999999999"' }
      )
    )
  end
end
