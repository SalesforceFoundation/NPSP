class NPSPMatchingDonationPage
  include PageObject

  text_field(:opp_name, id: 'opp3')
  text_field(:account_name, id: 'opp4')
  text_field(:amount, id: 'opp7')
  text_field(:close_date, id: 'opp9')
  select_list(:stage, id: 'opp11')
  button(:save_button, name: 'save')
end
