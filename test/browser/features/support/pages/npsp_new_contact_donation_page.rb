class NPSPNewContactDonationPage
  include PageObject

  div(:page_header, class: 'content')
  text_field(:opp_name, id: 'opp3')
  text_field(:acc_name, id: 'opp4')
end
