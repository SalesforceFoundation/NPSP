class NPSPMainPage
  include PageObject

  a(:accounts_tab, text: 'Accounts')
  a(:affiliations_link, text: 'Affiliations')
  a(:contacts_tab, class: 'contactBlock')
  a(:contacts_tab_on_page, text: 'Contacts')
  #img(:getting_started_link, title: 'Getting Started')
  #a(:leads_tab, text: 'Leads')
  a(:recurring_donations_link, text: 'Recurring Donations')
  #a(:npsp_data_imports_link, text: 'NPSP Data Imports')
  #a(:opportunities_link, text: 'Opportunities')
  #a(:payments_link, text: 'Payments')
  a(:contact_merge_link, text: 'Contact Merge')
  div(:home_page_text, class: 'content')
  div(:npsp_home_page_text, class: 'slds-media__body')
  button(:new_recurring_donations_button, name: 'new')
  img(:contact_merge, title: 'Contact Merge')
  img(:all_tabs, title: 'All Tabs')
  select_list(:view_tabs, id: 'p1')
end
