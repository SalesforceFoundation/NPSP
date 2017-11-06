class NPSPDataImportPage
  include PageObject

  text_field(:batch_size, index: 0)
  select_list(:contact_matching, index: 0)
  select_list(:contact_custom, index: 1)
  select_list(:account_custom, index: 2)
  button(:begin_button , value: 'Begin Data Import Process')
  div(:page_contents, class: 'slds-tile__detail')
end
