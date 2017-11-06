class NPSPAddressSettingsPage
  include PageObject

  text_field(:auth_token_text, name: /iAuth_Token__c/)
  checkbox(:enable_automatic_verification, name: /Enable_Automatic_Verification__c/)
  checkbox(:household_account_addresses_disabled, name: /cbxDHAA/)
  checkbox(:org_account_addrs_enabled, name: /cbxOAAE/)
  div(:page_contents, class: 'slds-form--horizontal slds-m-around--large')
  checkbox(:reject_ambiguous_addresses, name: /iReject_Ambiguous_Addresses__c/)
  checkbox(:simple_addr_change_is_update, name: /cbxSACT/)
  select_list(:verification_service, name: /iClass__c/)
end
