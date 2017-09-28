Given(/^the Begin button is disabled$/) do
  on(NPSPAccountConvertPage) do |page|
    page.wait_until do
      page.begin_conversion_element.disabled? == true
    end
  end
end

Given(/^the Account Field is visible$/) do
  on(NPSPAccountConvertPage) do |page|
    page.wait_until do
      page.account_field_element.visible? == true
    end
  end
end

When(/^I check all the boxes$/) do
  on(NPSPAccountConvertPage) do |page|
    page.all_users_element.when_present
    page.all_users_element.click
    page.my_data_element.click
    page.duplication_management_element.click
    page.the_conversion_element.click
    page.all_record_element.click
    page.all_workflows_element.click
    page.all_required_element.click
    page.i_am_aware_element.click
    page.all_non_npsp_element.click
    page.ive_consulted_element.click
    page.i_accept_element.click
  end
end

Then(/^the Begin button is not disabled$/) do
  expect(on(NPSPAccountConvertPage).begin_conversion_element.disabled?).to be false
end