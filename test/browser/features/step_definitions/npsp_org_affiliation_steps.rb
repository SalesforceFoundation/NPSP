Given(/^I create a new organization account via the API$/) do
  create_organization_account("test org account #{@random_string}")
end

When(/^I navigate to affiliations$/) do
  on(NPSPMainPage).affiliations_link_element.when_present.click
  on(NPSPAffiliationsPage).new_button
end

When(/^I fill in account and contact information$/) do
  on(NPSPAffiliationsPage) do |page|
    page.account_name_element.send_keys("test org account #{@random_string}")
    page.contact_name_element.send_keys("aaaatestcontact#{@random_string}")
  end
end

When(/^I click primary$/) do
  on(NPSPAffiliationsPage).check_primary_checkbox
end

When(/^I click Affiliations Save$/) do
  on(NPSPAffiliationsPage).save_button
end

Then(/^I should see my affiliations record$/) do
  on(NPSPAffiliationsPage) do |page|
    expect(page.content).to match /test org account #{@random_string}.+aaaatestcontact#{@random_string}/m
    expect(page.primary_check_image_element.visible?).to be(true)
  end
end
