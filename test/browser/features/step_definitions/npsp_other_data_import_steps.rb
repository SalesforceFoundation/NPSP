When(/^I click New$/) do
  on(NPSPOtherDataImportPage).new_button
end

When(/^I click View All$/) do
  on(NPSPOtherDataImportPage).go_button
end

When(/^I click Start Data Import$/) do
  on(NPSPOtherDataImportPage).start_data_import_button_element.when_present.click
end

Then(/^I should see the NPSP Batch Data Entry page$/) do
  expect(@browser.url).to match /BDI_DataImport\?retURL/
  step 'I set Batch Size to 60'
  step 'I set Contact Matching Rule to "First Name and Last Name"'
  step 'I set Contact Custom Unique ID to "--None--"'
  step 'I set Account Custom Unique ID to "--None--"'
  step 'I click Begin Data Import Process'
  step 'I should see the Data Import status'
end

Then(/^I should see the NPSP Data Import Edit page$/) do
  expect(on(NPSPOtherDataImportPage).page_info).to match /NPSP Data Import Edit.+New NPSP Data Import/m
end
