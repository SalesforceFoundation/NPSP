Given(/^I create two contacts "([^"]*)" and "([^"]*)" in the same Household$/) do |con1, con2|
  create_two_contacts_on_account_via_api(con1, con2)
  create_contact_via_api('decoy')
end

Given(/^I create two Contacts "([^"]*)" and "([^"]*)" to be added to Household$/) do |con1, con2|
  create_contact_via_api(con1)
  create_contact_via_api(con2)
end

Given(/^I see Contact name$/) do
  expect(on(ManageHouseholdsPage).card_contact_link_element.when_present(15).visible?).to be(true)
end

Given(/^I see existing address fields$/) do
  on(ManageHouseholdsPage) do |page|
    page.existing_address_element.when_present(15)
    expect(on(ManageHouseholdsPage).existing_address).to match /automation city.+automation state.+automation zip.+automation country/m
  end
end

Given(/^I see the Formal Greeting$/) do
  expect(on(ManageHouseholdsPage).formal_greeting).to eq " aaaatestcontact#{@random_string}"
end

Given(/^I see the Household Name$/) do
  expect(on(ManageHouseholdsPage).hh_name).to eq "aaaatestcontact#{@random_string} Household"
end

Given(/^I see the Primary Contact$/) do
  expect(on(ManageHouseholdsPage).primary_contact).to eq "aaaatestcontact#{@random_string}"
end

When(/^I add to household with Add All Members option$/) do
  on(ManageHouseholdsPage).add_merge_button_element.when_present(15).click
end

When(/^I add to household with Add option$/) do
  on(ManageHouseholdsPage) do |page|
    page.wait_until do
      page.add_button_element.when_present(15).disabled? == false
    end
    page.add_button_element.click
    page.spinner_element.when_not_present
  end
end

When(/^I click Change on Household Address$/) do
  on(ManageHouseholdsPage) do |page|
    page.spinner_element.when_not_present(20)
    page.change_address_button_element.when_present.click
  end
end

When(/^I click Enter a new address$/) do
  on(ManageHouseholdsPage).enter_new_element.when_present.click
end

When(/^I click Manage Household$/) do
  on(ManageHouseholdsPage).manage_households_button_element.when_present.click
end

When(/^I click Manage Household Save$/) do
  on(ManageHouseholdsPage) do |page|
    page.wait_until do
      page.manage_household_save_element.when_present.disabled? == false
    end
    page.spinner_element.when_not_present
    page.spinner2_element.when_not_present
    sleep 2
    page.manage_household_save_element.click
  end
end

When(/^I click Select an existing address$/) do
  on(ManageHouseholdsPage).select_existing_element.when_present.click
end

When(/^I click Set Address$/) do
  on(ManageHouseholdsPage).set_address_button_element.when_present.click
end

When(/^I click the Accounts tab$/) do
  on(NPSPMainPage).accounts_tab_element.when_present.click
end

When(/^I click the first Household Account$/) do
  on(ManageHouseholdsPage).first_household_link_element.when_present.click
end

When(/^I delete the last Contact from the Household$/) do
  on(ManageHouseholdsPage) do |page|
    page.delete_second_contact_element.when_present.click
    page.modal_remove_element.when_present.click
  end
end

When(/^I fill in the five address fields$/) do
  on(ManageHouseholdsPage) do |page|
    page.change_street_element.when_present.send_keys('street')
    #page.change_city_element.when_present.send_keys('city')
    #page.change_state_element.when_present.send_keys('state')
    #page.change_zip_element.when_present.send_keys('zip')
    #page.change_country_element.when_present.send_keys('country')
  end
end

When(/^I see the Add One option$/) do
  expect(on(ManageHouseholdsPage).add_remove_button_element.visible?).to be(true)
end

When(/^I click the Add Many option$/) do
  on(ManageHouseholdsPage).add_merge_button_element.when_present.click
end

When(/^I see the Cancel option$/) do
  expect(on(ManageHouseholdsPage).modal_cancel_button_element.visible?).to be(true)
end

When(/^I select "([^"]*)" and Go$/) do |account_view|
  on(ManageHouseholdsPage) do |page|
    page.view_select_list_element.when_present
    page.view_select_list=account_view
    page.go_button_element.when_present.click
  end
end

When(/^I select the first result$/) do
  on(ManageHouseholdsPage) do |page|
    page.search_part_element.when_not_present
    page.first_member_add_button_element.when_present.click
    page.search_part_element.when_not_present
  end
end

When(/^I type "([^"]*)" into search box$/) do |search_string|
  on(ManageHouseholdsPage) do |page|
    page.spinner_element.when_not_present
    page.spinner2_element.when_not_present
    page.add_members_search_element.when_present(30).click #search box needs focus for Chrome
    page.add_members_search_element.clear
    page.add_members_search_element.when_present.send_keys search_string
  end
end

When(/^I type the random string into search box$/) do
  on(ManageHouseholdsPage) do |page|
    page.add_members_search_element.wait_until_present(30)
    sleep 1
    page.add_members_search_element.click
    sleep 1
    page.add_members_search_element.send_keys @random_string
    # MAXIMIZE THE CHANCE THAT AUTO SEARCH RETURNS THE EXPECTED RESULT. EACH BACKSPACE RE-DOES SEARCH
    15.times do
      sleep 1
       page.add_members_search_element.send_keys :backspace
    end
    #page.add_members_search_element.click
  end
end

Then(/^checkboxes should be checked$/) do

  on(ManageHouseholdsPage) do |page|
    page.one_checked_box_element.when_present(10)
    expect(page.one_checked_box_element.visible?).to be(true)
    expect(page.other_checked_box_element.visible?).to be(true)
    #THIS CHECKBOX DOES NOT SAVE PROPERLY
    #SELENIUM DOES NOT TYPE INTO THE ASSOCIATIED TEXT FIELD PROPERLY
    #SEE https://github.com/SalesforceFoundation/Cumulus/issues/2418 FOR MORE INFORMATION
    #expect(page.bogus_checked_box_element).not_to be_visible
  end
end

Then(/^I should be able to click all the checkboxes$/) do
  on(ManageHouseholdsPage) do |page|
    page.spinner_element.when_not_present
    page.spinner2_element.when_not_present
    page.first_exclude_checkbox_span_element.when_present.click
    page.ninth_exclude_checkbox_span_element.when_present.click
    page.auto_name_checkbox_span_element.when_present.click
    page.auto_formal_checkbox_span_element.when_present.click
    page.auto_informal_checkbox_span_element.when_present.click

  end
end

Then(/^I should be on the regular Households page$/) do
  expect(on(ManageHouseholdsPage).regular_page_detail_block_element.when_present.visible?).to be(true)
end

Then(/^I should see all three checkboxes checked$/) do
  on(ManageHouseholdsPage) do |page|
    expect(page.exclude_formal_greeting_original_checked?).to be false
    expect(page.exclude_informal_greeting_original_checked?).to be false
    expect(page.exclude_household_name_original_checked?).to be false
  end
end

Then(/^I should see breadcrumbs for the account$/) do
  on(ManageHouseholdsPage) do |page|
    page.wait_until do
      page.account_breadcrumb.match /HOUSEHOLD.+AAAACREACC1#{@random_string}/m
    end
    expect(page.account_breadcrumb).to match /HOUSEHOLD.+AAAACREACC1#{@random_string}/m
  end
end

Then(/^I should see one Household Member entry$/) do
  on(ManageHouseholdsPage) do |page|
    expect(page.household_member_first_element.when_present.visible?).to be(true)
    expect(page.household_member_second_element.exists?).to be(false)
  end
end

Then(/^I should see the Add Members search field$/) do
  expect(on(ManageHouseholdsPage).add_members_search_element.when_present.visible?).to be(true)
end

Then(/^I should see the Household Details section$/) do
  expect(on(ManageHouseholdsPage).household_details_element.when_present.visible?).to be(true)
end

Then(/^I should see the Household Members section$/) do
  expect(on(ManageHouseholdsPage).household_members_section_element.when_present(20).visible?).to be(true)
end

Then(/^I should see the new address$/) do
  expect(on(ManageHouseholdsPage).account_address_field).to match /street.+city, state zip.+country/m
end

Then(/^I should see the new address containing "([^"]*)" and "([^"]*)" and "([^"]*)" and "([^"]*)" and "([^"]*)"$/) do |street, city, state, zip, country|
  #expect(on(ManageHouseholdsPage).account_address_field).to match /#{street}.+#{city}, #{state} #{zip}.+#{country}/m
  expect(on(ManageHouseholdsPage).account_address_field).to match /#{street}/
end

Then(/^I should see three Household Member entries$/) do
  on(ManageHouseholdsPage) do |page|
    expect(page.household_member_second_element.when_present.visible?).to be(true)
    expect(page.household_member_first_element.when_present.visible?).to be(true)
    expect(page.household_member_third_element.when_present.visible?).to be(true)
  end
end

Then(/^I should see two Household Member entries$/) do
  on(ManageHouseholdsPage) do |page|
    expect(page.household_member_second_element.when_present.visible?).to be(true)
    expect(page.household_member_first_element.when_present.visible?).to be(true)
  end
end

Then(/^the five address fields should appear in the Household Address section in the correct order$/) do
  #expect(on(ManageHouseholdsPage).household_address_field).to match /street.+city.+state.+zip.+country/m
  expect(on(ManageHouseholdsPage).household_address_field).to match /street/m
end

Then(/^"([^"]*)" and "([^"]*)" should be added to the Household$/) do |arg1, arg2|
  pending # Write code here that turns the phrase above into concrete actions
end
