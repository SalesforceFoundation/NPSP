
When(/^I change Recurring Donations settings$/) do
  on(NPSPRecurringDonationsSettingsPage) do |page|
    on(NPSPSettingsPage).edit_rc_button_element.when_present.click
    step 'I wait for the page to revert'
    5.times do
      page.opp_forecast_months_element.when_present.click
      page.opp_forecast_months_element.send_keys( :backspace )
    end
    page.opp_forecast_months_element.send_keys('24')
    page.opp_behavior='Delete_Open_Opportunities'
  end
end

When(/^I click Save Recurring Donations Settings$/) do
  api_client do
    @these_settings =  select_api 'select Id,
                                       Name,
                                       Opportunity_Forecast_Months,
                                       Open_Opportunity_Behavior
                                       from Recurring_Donations_Settings'
  end

  @these_settings = @these_settings.first

  sleep 1 #API CALL NEEDS TO PROPAGATE BEFORE CLICKING SAVE BUTTON
  on(NPSPRecurringDonationsSettingsPage).save_button_element.click
end

Then(/^Recurring Donations settings should be saved$/) do
  on(NPSPRecurringDonationsSettingsPage) do |page|
    page.page_opp_forecast_months_saved_element.when_present(30)
    expect(page.page_opp_forecast_months_saved_element.visible?).to be(true)
    expect( page.page_opp_behavior_saved_element.visible?).to be(true)
  end
end

Then(/^when I refresh the page my changes should be visible$/) do
  @browser.refresh
  step 'I navigate to Recurring Donations Recurring Donations'
  step 'Recurring Donations settings should be saved'
end
