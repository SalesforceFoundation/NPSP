class NPSPRecurringDonationsPage
  include PageObject

  div(:subsection, class: 'pbSubsection')
  select_list(:period_select) { |page| page.subsection_element.select_list_element }

  text_field(:amount, index: 7)
  text_field(:contact_field, index: 5)
  a(:delete_link, text: 'Del')
  text_field(:donation_name, id: 'Name')
  div(:donations_section, id: /_body/)
  text_field(:installments_field, index: 8)
  button(:new_button, name: 'new')
  button(:refresh_button, name: 'npe03__refresh_opportunities')
  button(:save_button, name: 'save')
end
