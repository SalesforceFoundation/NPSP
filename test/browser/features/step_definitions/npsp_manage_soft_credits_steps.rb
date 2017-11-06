Given(/^I populate Soft Credit Role with "([^"]*)"$/) do |role|
  populate_soft_credit(role)
end

When(/^I add a new soft credit for a bogus Contact with a Role for full amount$/) do
  on(NPSPManageSoftCreditsPage) do |page|
    page.new_credit
    page.contact_field_element.when_present
    page.contact_field = 'BOGUS'
    page.role_name = 'Influencer'

    page.save_button
  end
end

When(/^I add a new soft credit for the second Contact with a Role for amount "([^"]*)"$/) do |amount|
  on(NPSPManageSoftCreditsPage) do |page|
    page.new_credit
    page.contact_field_element.when_present
    page.contact_field = 'Second'
    page.role_name = 'Influencer'
    #page.select_full_button #FULL AMOUNT AUTOMATICALLY FILLS IN SOFT CREDIT REGARDLESS OF WHAT IS TYPED
    page.amount_element.send_keys amount
    page.save_button
  end
end

When(/^I add a new soft credit for the second Contact with a Role for full amount$/) do
  on(NPSPManageSoftCreditsPage) do |page|
    page.new_credit
    page.contact_field_element.when_present
    page.contact_field = 'Second'
    page.role_name = 'Influencer'
    page.select_full_button #FULL AMOUNT AUTOMATICALLY FILLS IN SOFT CREDIT REGARDLESS OF WHAT IS TYPED
  end
end

When(/^I add a soft credit$/) do
  on(NPSPManageSoftCreditsPage).add_soft_credit_link_element.when_present.click
end

When(/^I delete a soft credit$/) do
  on(NPSPManageSoftCreditsPage).delete_soft_credit_button_element.when_present.click
end

Then(/^the Manage Soft Credits page should have no credits visible$/) do
  on(NPSPManageSoftCreditsPage) do |page|
    Watir::Wait.while { page.delete_soft_credit_button_element.present? }
    expect(page.delete_soft_credit_button_element.exist?).to be(false)
  end
end

When(/^I click Allow soft credit more than amount$/) do
  on(NPSPManageSoftCreditsPage).check_allow_check
end

When(/^I click Percent$/) do
  on(NPSPManageSoftCreditsPage).select_percent_button
end

Then(/^I should see "([^"]*)" in the Amount field and Save$/) do |amount|
  on(NPSPManageSoftCreditsPage) do |page|
    page.amount_read_only_element.when_present
    expect(page.amount_read_only).to eq amount
    page.save_button
  end
end

Then(/^I should see the bad Contact error$/) do
  on(NPSPManageSoftCreditsPage) do |page|
    page.contact_error_element.when_present
    expect(page.contact_error).to eq "Error: Contact: No matches found."
  end
end

Then(/^I should see the Manage Soft Credits page$/) do
  on(NPSPManageSoftCreditsPage) do |page|
    expect(page.body_content).to match /Primary Donor.+Total Amount.+Soft Credit Amount.+Total Unaccounted.+SOFT CREDIT RESTRICTIONS.+Amount.+Percent.+Allow Soft Credit Amount more than Total Amount/m
  end
end

Then(/^I should see the new Contact Role on the Opportunity$/) do
  on(NPSPManageSoftCreditsPage) do |page|
    page.related_contact_role_list_element.when_present
    expect(page.related_contact_role_list).to match /Second.+Second Household/
  end
end
