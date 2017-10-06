When(/^I retrieve current settings for Account Model, Household Account Record Type, One\-to\-One Record Type$/) do
  on(NPSPAccountModelSettingsPage) do |page|
    @account_model_setting = page.account_model_select
    @household_account_record_type = page.household_account_record_type
    @one_to_one_record_type = page.one_to_one_record_type
  end
end

When(/^I click Edit People Account Model$/) do
  on(NPSPSettingsPage).edit_am_button_element.when_present.click
  expect(on(NPSPAccountModelSettingsPage).save_button_element.when_present(15).visible?).to be(true)
end

When(/^I click Save Account Model Settings$/) do
  # do we need this for validation or is it just clean-up?
  api_client do
    @these_settings =  select_api 'select Id,
                                       Name,
                                       HH_Account_RecordTypeID
                                       from Contacts_And_Orgs_Settings'
  end

  @these_settings = @these_settings.first

  sleep 1 #API CALL NEEDS TO PROPAGATE BEFORE CLICKING SAVE BUTTON
  on(NPSPRecurringDonationsSettingsPage).save_button
end

When(/^I set Account Model to "([^"]*)"$/) do |account_model_value|
  on(NPSPAccountModelSettingsPage).account_model_select = account_model_value
end

When(/^I set Household Account Record Type to "([^"]*)"$/) do |household_record_type|
  on(NPSPAccountModelSettingsPage).household_account_record_type = household_record_type
end

When(/^I set One\-to\-One Record Type to "([^"]*)"$/) do |one_to_one_type|
  on(NPSPAccountModelSettingsPage).one_to_one_record_type = one_to_one_type
end

Then(/^I should see the default Account Model settings on the page$/) do
  #value "- none -" appears on the edit page but does not appear on the display page
  if @account_model_setting == '--None--'
    @account_model_setting = ''
  end
  if @household_account_record_type == '--None--'
    @household_account_record_type = ''
  end
  if @one_to_one_record_type == '--None--'
    @one_to_one_record_type = ''
  end

  expect(on(NPSPAddressSettingsPage).page_contents).to match /#{@account_model_setting}.+#{@household_account_record_type}.+#{@one_to_one_record_type}/m
end

Then(/^Account Model save should be completed$/) do
  expect(on(NPSPAccountModelSettingsPage).edit_button_element.when_present(30).visible?).to be(true)
end

Then(/^Account Model changes should be visible$/) do
  expect(on(NPSPAccountModelSettingsPage).changed_account_model_element.visible?).to be(true)
end
