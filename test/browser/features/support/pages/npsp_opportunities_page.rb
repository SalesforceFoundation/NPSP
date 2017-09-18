class NPSPOpportunitiesPage
  include PageObject

  text_field(:account_name, id: 'opp4')
  button(:new_button, title: 'New')
  a(:today_link, href: /DatePicker/)
  text_field(:opp_name, id: 'opp3')
  select_list(:opp_stage, id: 'opp11')
  text_field(:opp_amount, id: 'opp7')
  button(:save_button, name: 'save')
  button(:go_button, name: 'go')
  a(:payment_edit_link, text: 'Edit')
  text_field(:payment_amount, value: '100.00')
  span(:payment_page_link, text: /PMT/)
end
