class NPSPManageSoftCreditsPage
  include PageObject

  link(:add_soft_credit_link, text: 'Add another soft credit')
  checkbox(:allow_check, id: /allowTooManySoftCredits/)
  text_field(:amount, class: 'slds-input')
  span(:amount_read_only, class: 'slds-form-element__static')
  div(:body_content, class: 'myBodyContent')
  h2(:contact_error, class: 'slds-text-heading--small', index: 1)
  text_field(:contact_field, class: 'lookupInput')
  button(:delete_soft_credit_button, id: /delRowBTN/)
  radio_button(:full_button, index: 2)
  a(:new_credit, text: 'Add another soft credit')
  radio_button(:percent_button, index: 1)
  div(:related_contact_role_list, id: /RelatedContactRoleList_body/)
  select_list(:role_name, class: 'slds-select')
  button(:save_button, value: 'Save')
end
