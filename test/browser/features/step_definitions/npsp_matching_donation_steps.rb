Then(/^Matching Donation Opportunity Name should match "([^"]*)" plus the Contact Account Name$/) do |opp_name|
  expect(on(NPSPMatchingDonationPage).opp_name).to match /#{opp_name} #{@contact_name} Household/
end

Then(/^Account Name shoujld be the Account for the Contact created$/) do
  expect(on(NPSPMatchingDonationPage).account_name).to eq "#{@contact_name} Household"
end

Then(/^Amount should be "([^"]*)"$/) do |amount|
  expect(on(NPSPMatchingDonationPage).amount).to eq amount
end

Then(/^Close Date should be "([^"]*)"$/) do |close_date_value|
  expect(on(NPSPMatchingDonationPage).close_date).to eq close_date_value
end

Then(/^Stage should be "([^"]*)"$/) do |stage|
  expect(on(NPSPMatchingDonationPage).stage).to eq stage
end

Then(/^Save button should be enabled$/) do
  expect(on(NPSPMatchingDonationPage).save_button_element.disabled?).to be false
end
