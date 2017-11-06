Given(/^I create a GAU named "([^"]*)"$/) do |gau_name|
  create_gau_via_api(gau_name + @random_string)
  @array_of_gaus << @gau_id
  @gau_names << gau_name + @random_string
end

When(/^I add a row$/) do
  on(NPSPManageAllocationsPage) do |page|
    page.add_row_button_element.when_present.click
    page.second_row_percent_element.when_present
  end
end

When(/^I enter "([^"]*)" in the Amount for the first row for the first GAU$/) do |amount|
  on(NPSPManageAllocationsPage) do |page|
    page.first_gau_field = @gau_names[0]
    page.first_row_amount = amount
  end
end

When(/^I enter "([^"]*)" in the Percent for the second row for the second GAU$/) do |percent|
  on(NPSPManageAllocationsPage) do |page|
    page.second_gau_field = @gau_names[1]
    page.second_row_percent = percent
  end
end

When(/^I enter "([^"]*)" in the Percent for the first row for the first GAU$/) do |percent|
  on(NPSPManageAllocationsPage) do |page|
    page.first_gau_field = @gau_names[0]
    page.first_row_percent = percent
  end
end

When(/^I enter "([^"]*)" in the Percent for the second row for the first GAU$/) do |percent|
  on(NPSPManageAllocationsPage) do |page|
    page.second_gau_field = @gau_names[0]
    page.second_row_percent = percent
  end
end

When(/^I click Save$/) do
  on(NPSPManageAllocationsPage).save_and_close_button
end

Then(/^Delete Row should be present$/) do
  expect(on(NPSPManageAllocationsPage).delete_row_button_element.visible?).to be(true)
end

Then(/^Percent in the first row should be disabled$/) do
  expect(on(NPSPManageAllocationsPage).first_row_percent_element.disabled?).to be(true)
end

Then(/^Amount in the second row should be disabled$/) do
  expect(on(NPSPManageAllocationsPage).second_row_amount_element.disabled?).to be(true)
end

Then(/^Save should be present$/) do
  expect(on(NPSPManageAllocationsPage).save_and_close_button_element.visible?).to be(true)
end

Then(/^I should see a remainder of "([^"]*)"$/) do |rem|
  expect(on(NPSPManageAllocationsPage).remainder_amount).to eq rem
end

Then(/^I should see an error message "([^"]*)"$/) do |msg|
  on(NPSPManageAllocationsPage) do |page|
    page.wait_until do
      page.error_message_element.visible? == true
    end
  expect(page.error_message).to match msg
  end
end

Then(/^I should see the Save button disabled$/) do
  expect(on(NPSPManageAllocationsPage).save_and_close_button_element.disabled?).to be true
end
