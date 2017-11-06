When(/^I click Enable Automatic Verification$/) do
  on(NPSPAddressSettingsPage).check_enable_automatic_verification
end

When(/^I click Household Account Addresses Disabled$/) do
  on(NPSPAddressSettingsPage).check_household_account_addresses_disabled
end

When(/^I click Organizational Account Addresses Enabled$/) do
  on(NPSPAddressSettingsPage).check_org_account_addrs_enabled
end

When(/^I click Reject Ambiguous Addresses$/) do
  on(NPSPAddressSettingsPage).check_reject_ambiguous_addresses
end

When(/^I click Simple Address Change Treated as Update$/) do
  on(NPSPAddressSettingsPage).check_simple_addr_change_is_update
end

When(/^I select "([^"]*)"$/) do |verification_service|
  on(NPSPAddressSettingsPage).verification_service=verification_service
end

When(/^I type "([^"]*)" into Auth Token text area$/) do |auth_token_text|
  on(NPSPAddressSettingsPage).auth_token_text_element.when_present.send_keys(auth_token_text)
end

Then(/^"([^"]*)" should be selected$/) do |select_value|
  expect(on(NPSPAddressSettingsPage).verification_service).to be == select_value
end

Then(/^all three checkboxes should be clicked$/) do
  on(NPSPAddressSettingsPage) do |page|
    expect(page.household_account_addresses_disabled_checked?).to be true
    expect(page.org_account_addrs_enabled_checked?).to be true
    expect(page.simple_addr_change_is_update_checked?).to be true
  end
end

Then(/^Enable Automatic Verification should be checked$/) do
  expect(on(NPSPAddressSettingsPage).enable_automatic_verification_checked?).to be true
end

Then(/^Reject Ambiguous Addresses should be checked$/) do
  expect(on(NPSPAddressSettingsPage).reject_ambiguous_addresses_checked?).to be true
end

Then(/^the text "([^"]*)" should not be visible on the page$/) do |unselected_value|
  expect(on(NPSPAddressSettingsPage).page_contents_element.text).not_to match unselected_value
end
