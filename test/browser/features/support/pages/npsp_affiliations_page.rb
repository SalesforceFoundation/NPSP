class NPSPAffiliationsPage
  include PageObject

  text_field(:account_name, index: 1)
  image(:primary_check_image, alt: 'Checked')
  text_field(:contact_name, index: 2)
  cell(:content, id: 'bodyCell')
  button(:new_button, name: 'new')
  checkbox(:primary_checkbox, value: '1')
  button(:save_button, name: 'save')
end
