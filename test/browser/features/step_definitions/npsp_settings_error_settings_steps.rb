
When(/^I change System Tools Error Notifications$/) do
  on(NPSPErrorSettingsPage) do |page|
    on(NPSPSettingsPage).edit_err_button_element.when_present.click
    step 'I wait for the page to revert'
      #page.uncheck_store_errors
      #WANT TO ALWAYS FIND A CHECKED CHECKBOX HERE SO NO EXPLICIT 'uncheck'
    page.store_errors_element.when_present.click
  end
end

When(/^I click Save System Tools Error Notifications$/) do
  api_client do
    @these_settings =  select_api 'select Id,
                                       Name,
                                       Store_Errors_On,
                                       Error_Notifications_On
                                       from Error_Settings'
  end

  @these_settings = @these_settings.first

  sleep 1 #API CALL NEEDS TO PROPAGATE BEFORE CLICKING SAVE BUTTON
  on(NPSPRecurringDonationsSettingsPage).save_button
end

Then(/^System Tools Error Notifications settings should be saved$/) do
  on(NPSPErrorSettingsPage) do |page|
    page.page_store_errors_saved_element.when_present(30)
    expect( page.page_store_errors_saved_element.visible?).to be(true)
    expect( page.page_error_notifications_saved_element.visible?).to be(true)
    on(NPSPSettingsPage).edit_err_button_element.when_present.click
    page.store_errors_element.when_present(30)
    expect(page.store_errors_checked?).to be false
    expect(page.error_notifications_checked?).to be false
  end
end

Then(/^when I refresh the page my System Tools Error Notifications changes should be visible$/) do
  @browser.refresh
  step 'I navigate to System Tools Error Notifications'
  sleep 1
  step 'System Tools Error Notifications settings should be saved'
end
