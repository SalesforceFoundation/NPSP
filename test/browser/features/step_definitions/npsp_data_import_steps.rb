When(/^I set Batch Size to (\d+)$/) do |batch_size|
  on(NPSPDataImportPage).batch_size = batch_size
end

When(/^I set Contact Matching Rule to "([^"]*)"$/) do |con_mat|
  on(NPSPDataImportPage).contact_matching = con_mat
end

When(/^I set Contact Custom Unique ID to "([^"]*)"$/) do |con_cust|
  on(NPSPDataImportPage).contact_custom = con_cust
end

When(/^I set Account Custom Unique ID to "([^"]*)"$/) do |acc_cust|
  on(NPSPDataImportPage).account_custom = acc_cust
end

When(/^I click Begin Data Import Process$/) do
  on(NPSPDataImportPage).begin_button
end

Then(/^I should see the Data Import status$/) do
  on(NPSPDataImportPage) do |page|
    page.page_contents_element.when_present
    page.wait_until do
      page.page_contents.match /Current Status.+Completed/m
    end
    expect(page.page_contents).to match /Time.+Records processed.+Records imported.+Records failed/m
  end
end