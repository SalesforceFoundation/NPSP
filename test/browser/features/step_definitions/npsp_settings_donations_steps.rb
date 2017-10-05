When(/^I change Donations Batch Entry settings$/) do
  on(NPSPDonationsSettingsPage).unsaved_page_donations_element.when_present

  on(NPSPSettingsPage).edit_dbe_button_element.when_present.click
  step 'I wait for the page to revert'

  on(NPSPDonationsSettingsPage) do |page|
    page.opp_naming_checkbox_element.when_present(30)
    page.uncheck_opp_naming_checkbox
  end
end


When(/^I click Save Donations Batch Entry settings$/) do
  api_client do
    @these_settings = select_api 'select Id,
                                          Name,
                                          Allow_Blank_Opportunity_Names,
                                          Opportunity_Naming
                                          from Batch_Data_Entry_Settings'
  end

  @these_settings = @these_settings.first

  sleep 1 #API CALL NEEDS TO PROPAGATE BEFORE CLICKING SAVE BUTTON
  on(NPSPRecurringDonationsSettingsPage).save_button
end

Then(/^Donations Batch Entry settings should be saved$/) do
  on(NPSPDonationsSettingsPage) do |page|
    page.saved_opp_naming_checkbox_element.when_present(30)
    expect(page.saved_opp_naming_checkbox_element.visible?).to be(true)
  end
end

Then(/^when I refresh the Donations Batch Entry page my changes should be visible$/) do
  @browser.refresh
  step 'I navigate to Settings Donations Batch Entry'
  sleep 1
  step 'Donations Batch Entry settings should be saved'
end
