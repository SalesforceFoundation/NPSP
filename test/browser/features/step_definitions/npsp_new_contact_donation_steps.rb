Given(/^I create two Contacts in the same Household via the API$/) do
  create_two_contacts_on_account_via_api("aaaatestcontact1_#{@random_string}", "aaaatestcontact2_#{@random_string}")
end

Then(/^I should see the New Opportunity page$/) do
  expect(on(NPSPNewContactDonationPage).page_header).to match /Opportunity Edit.+New Opportunity/m
end

Then(/^Opportunity Name should be set to the correct value$/) do
  expect(on(NPSPNewContactDonationPage).opp_name).to eq @contact_name + '- Donation {!Today}'
end

Then(/^Account Name should be set to the correct value$/) do
  expect(on(NPSPNewContactDonationPage).acc_name).to eq @contact_name + ' Household'
end

Then(/^Account Name should be set to the two contact Household$/) do
  expect(on(NPSPNewContactDonationPage).acc_name).to eq @array_of_contact_names[0] + ' and ' + @array_of_contact_names[1] + ' Household'
end
