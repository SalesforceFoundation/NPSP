class NPSPContactsPage
  include PageObject

  select_list(:all_contacts, name: 'fcf')
  button(:go_button, name: 'go')
  text_field(:contact_search_box, id: 'contactMergePage:searchForm:searchText')
  div(:contacts_display, class: 'x-grid3-body')
  a(:merged_account, text: 'aaa2')
  table(:contact_data, class: 'detailList')
end
