class NPSPDonationsSettingsPage
  include PageObject

  div(:unsaved_page_donations, text: /Opportunity Naming/)
  checkbox(:opp_naming_checkbox, id: /cbxONC/)
  checkbox(:saved_opp_naming_checkbox, id: /cbxONC/, disabled: 'disabled')
end
