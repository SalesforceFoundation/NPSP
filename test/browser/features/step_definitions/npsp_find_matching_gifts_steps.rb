Given(/^I create two Opportunities to be matched$/) do

  create_two_contacts_on_different_accounts("First", "Second")

  create_opportunity_via_api("ToBeMatched#{@random_string}",
                             'Closed Won',
                             '2020-01-01',
                             '100',
                             @account_id_for_second_contact,
                             'Potential',
                             @account_id_for_first_contact)

  create_opportunity_via_api("OrigMatch#{@random_string}",
                             'Closed Won',
                             '2020-01-01',
                             '100',
                             @account_id_for_first_contact,
                             'Submitted',
                             @account_id_for_second_contact)
end


When(/^I click Matching Gift Save$/) do
  on(FindMatchingGiftsPage).save_match_gift
end

When(/^I click the checkbox for the matching Opportunity$/) do
  on(FindMatchingGiftsPage).check_match_checkbox
end

Then(/^I should be able to search for matching opportunities$/) do
  on(FindMatchingGiftsPage) do |page|
    page.find_more_gifts
    expect(page.fifth_text_field_element.when_present.visible?).to be(true)
    expect(page.content).to match /Account.+Primary Contact.+Amount.+Close Date Start.+Close Date End/m
  end
end

Then(/^I should see a Cancel button$/) do
  expect(on(FindMatchingGiftsPage).cancel_button_element.visible?).to be(true)
end

Then(/^I should see the headers for matching opportunities$/) do
  expect(on(FindMatchingGiftsPage).matching_gift_headers).to match /SELECT.+NAME.+ACCOUNT.+PRIMARY CONTACT.+AMOUNT.+CLOSE DATE/
end

Then(/^I should see the information for my opportunity$/) do
  on(FindMatchingGiftsPage) do |page|
    page.opportunity_info_element.when_present
    expect(page.opportunity_info).to match /TOTAL MATCHING GIFT.+\$100\.00.+MATCHING GIFT PERCENT.+100%.+TOTAL SELECTED.+\$0\.00.+TOTAL UNACCOUNTED.+\$100\.00/m
  end
end


Then(/^when I click Search I should see an error "([^"]*)" and "([^"]*)"$/) do |warning, content|
  on(FindMatchingGiftsPage) do |page|
    page.search_button
    page.wait_until do
      page.error_message_element.visible? == true
    end
    expect(page.error_message).to match /#{warning}.+#{content}/m
  end
end

Then(/^I should be on the Opportunity page for the original Opportunity$/) do
  on(FindMatchingGiftsPage) do |page|
    page.opp_page_header_element.when_present
    expect(page.opp_page_header).to eq "OrigMatch#{@random_string}"
  end
end
