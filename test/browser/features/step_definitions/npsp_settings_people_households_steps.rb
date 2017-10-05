
When(/^I click Edit Household Name Settings/) do
  on(NPSPSettingsPage).edit_hh_button_element.when_present.click
  step 'I wait for the page to revert'
end

When(/^I retrieve existing values/) do
  on (NPSPHouseholdsSettingsPage) do |page|
    @contact_overrun = Regexp.escape page.contact_overrun
    @formal_greetimg_format = Regexp.escape page.formal_greetimg_format
    @mail_list_report = Regexp.escape page.mail_list_report
    @hh_name_format = Regexp.escape page.hh_name_format
    @hh_obj_rule = Regexp.escape page.hh_obj_rule
    @implementing_class = Regexp.escape page.implementing_class
    @informal_greetimg_format = Regexp.escape page.informal_greetimg_format
    @name_connector = Regexp.escape page.name_connector
    @name_overrun = Regexp.escape page.name_overrun
  end
end

When(/^I set Contact Overrun Count to "([^"]*)"$/) do |cont_over|
  on(NPSPHouseholdsSettingsPage).contact_overrun=cont_over
end

When(/^I set Formal Greeting Format to "([^"]*)"$/) do |f_greet|
  on(NPSPHouseholdsSettingsPage).formal_greetimg_format=f_greet
end

When(/^I set Household Mailing List Report to "([^"]*)"$/) do |mail_list|
  on(NPSPHouseholdsSettingsPage).mail_list_report=mail_list
end

When(/^I set Household Name Format to "([^"]*)"$/) do |hh_name|
  on(NPSPHouseholdsSettingsPage).hh_name_format=hh_name
end

When(/^I set Household Object Rules to "([^"]*)"$/) do |h_rule|
  on(NPSPHouseholdsSettingsPage).hh_obj_rule=h_rule
end

When(/^I set Implementing Class to "([^"]*)"$/) do |imp_class|
  on(NPSPHouseholdsSettingsPage).implementing_class=imp_class
end

When(/^I set Informal Greeting Format to "([^"]*)"$/) do |if_greet|
  on(NPSPHouseholdsSettingsPage).informal_greetimg_format=if_greet
end

When(/^I set Name Connector to "([^"]*)"$/) do |n_conn|
  on(NPSPHouseholdsSettingsPage).name_connector=n_conn
end

When(/^I set Name Overrun to "([^"]*)"$/) do |n_over|
  on(NPSPHouseholdsSettingsPage).name_overrun=n_over
end

When(/^I uncheck Automatic Household Naming$/) do
  on(NPSPHouseholdsSettingsPage).uncheck_automatic_hh_naming
end

When(/^I click Save Household Naming Settings$/) do
  api_client do
    @these_settings =  select_api 'select Id,
                                       Name,
                                       Household_Name_Format
                                       from Household_Naming_Settings'
  end

  @these_settings = @these_settings.first

  sleep 1 #API CALL NEEDS TO PROPAGATE BEFORE CLICKING SAVE BUTTON
  on(NPSPRecurringDonationsSettingsPage).save_button
end

Then(/^my Household Naming Settings should be saved$/) do
  on(NPSPHouseholdsSettingsPage) do |page|
    page.page_name_format_saved_element.when_present(30)
    expect(page.page_name_format_saved_element.visible?).to be(true)
  end
end

Then(/^when I refresh the page my Household Naming Settings should be saved$/) do
  @browser.refresh
  step 'I navigate to Settings People Households'
  step 'my Household Naming Settings should be saved'
end

Then(/^Examples for Household Name Format should reflect my changes$/) do
  on(NPSPHouseholdsSettingsPage) do |page|
    page.example_text_box_element.click
    page.wait_until do
      page.example_text_box.match "Sam, Sally foo Suzie"
    end
    expect(page.example_text_box).to match /Smith \(Sam\) Household\s+Smith \(Sam foo Sally\) Household\s+Smith \(Sam, Sally foo Suzie\) Household\s+Smith \(Sam, Sally foo Suzie\) foo Doe \(Daphne\) Household\s+Smith \(Sam, Sally foo Suzie\) foo Doe \(Daphne foo Donald\) Household/m
  end
end

Then(/^I should see the original Household Settings on the page$/) do
  expect(on(NPSPHouseholdsSettingsPage).hh_page_contents).to match /#{@hh_name_format}.+#{@formal_greetimg_format}.+#{@informal_greetimg_format}.+#{@name_connector}.+#{@name_overrun}.+#{@contact_overrun}.+#{@implementing_class}.+#{@hh_obj_rule}.+#{@hh_creation_excluded}/m
end


