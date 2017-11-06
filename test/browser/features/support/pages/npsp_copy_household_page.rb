class NPSPCopyHouseholdPage
  include PageObject

  div(:mailingcity, id: 'con19_ileinner')
  button(:copy_addresses_button, text: 'Copy Household Address to Contacts')
end
