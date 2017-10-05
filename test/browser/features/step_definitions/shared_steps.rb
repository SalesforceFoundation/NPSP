Given(/^I create new Contacts with Household Object via the API$/) do
  create_contacts_with_household_object_via_api("aaahhobj#{@random_string}", "aaahhobjcontact#{@random_string}")
  @array_of_contacts << @contact_id
end

Given(/^I create a new Contact via the API$/) do
  create_contact_via_api("aaaatestcontact#{@random_string}")
end

Given(/^I create a new Contact via the API with address "([^"]*)" "([^"]*)" "([^"]*)" "([^"]*)" "([^"]*)"$/) do |street, city, state, country, zip|
  create_contact_via_api("aaaatestcontact#{@random_string}", street, city, state, country, zip)
end

Given(/^I create a second Contact via the API with address "([^"]*)" "([^"]*)" "([^"]*)" "([^"]*)" "([^"]*)"$/) do |street, city, state, country, zip|
  create_contact_via_api("aaaaSECONDcontact#{@random_string}", street, city, state, country, zip)
end

Given(/^I create a new Opportunity via the API with stage name "([^"]*)" and close date "([^"]*)" and amount "([^"]*)"$/) do |stage_name, close_date, amount|
  create_opportunity_via_api("aaaatestopp#{@random_string}", stage_name, close_date, amount, @account_id)
end

Given(/^I create a new random account via the API$/) do
  create_account_via_api("aaaacreacc1#{@random_string}")
end

When(/^I click Cancel$/) do
  on(ManageHouseholdsPage) do |page|
    page.wait_until do
      page.cancel_button_element.disabled? == false
    end
    sleep 1 #CODE BEHIND THE CANCEL BUTTON NEEDS TO LOAD BEFORE CLICK
    page.cancel_button
  end
end

When(/^I wait for the page to revert$/) do
  on(NPSPSettingsPage) do |page|
    page.wait_until(30) do
      page.loading_message_element.visible? == false
    end
  end
end

Then(/^I should be on the Account page for a single Household$/) do
  on(ManageHouseholdsPage) do |page|
    page.wait_until do
      page.page_title_element.when_present
    end
    expect(page.page_title).to eq "aaaatestcontact#{@random_string} Household"
    expect(page.account_label).to eq 'Account'
  end
end

Then(/^I should be on the Account page for a merged Household$/) do
  on(ManageHouseholdsPage) do |page|
    page.wait_until do
      page.page_title_element.when_present
    end
    expect(page.page_title).to eq "aaaatestcontact#{@random_string} and aaaaSECONDcontact#{@random_string} Household"
    expect(page.account_label).to eq 'Account'
  end
end

Then(/^I should see the Payment page$/) do
  on(PaymentWizardPage) do |page|
    page.wait_until do
      page.payment_page_header_element.visible? == true
    end
    expect(page.payment_page_header).to eq 'Payment'
  end
end

Then(/^the payment amount should be "([^"]*)"$/) do |payment_amount|
  expect(on(PaymentWizardPage).payment_page_amount).to eq payment_amount
end
