Given(/^I create a new Lead via the API$/) do
  create_lead_via_api(@random_string, @random_string)
end

When(/^I change some settings$/) do
  on(NPSPLeadConvertPage) do |page|
    page.check_do_not_create_opp
    page.opportunity_account = 'Affiliated Account'
  end
end

When(/^I click Convert$/) do
  on(NPSPLeadConvertPage) do |page|
    page.convert_button
    page.convert_button_element.when_not_present
  end
end

Then(/^I should be able to click the link to the Household Account for the contact$/) do
  on(NPSPLeadConvertPage) do |page|
    page.household_link_element.when_present.click
    page.wait_until do
      page.page_contents_element.visible? == true
    end
    expect(page.page_contents).to match "#{@random_string} Household"
  end
end

Then(/^I should be on the Lead page for the Contact$/) do
  on(NPSPLeadConvertPage) do |page|
    expect(page.page_contents).to match @random_string
  end
end

Then(/^I should be on the new Contact page for the Lead$/) do
  on(NPSPLeadConvertPage) do |page|
    expect(page.page_contents).to match @random_string
  end
end

Then(/^I should see the Lead Convert page for the Lead$/) do
  on(NPSPLeadConvertPage) do |page|
    expect(page.email_to_owner_checkbox_element.visible?).to be(true)
    expect(page.contact_select).to eq "Create New: #{@random_string}"
    expect(page.opportunity_name).to eq @random_string
    expect(page.do_not_create_opp_checked?).to be true
    expect(page.opportunity_account).to eq 'Contact Account'
    expect(page.converted_status).to eq 'Closed - Converted'
    expect(page.convert_button_element.visible?).to be(true)
    expect(page.cancel_button_element.visible?).to be(true)
  end
end

Then(/^the Lead record for this person should no longer exist$/) do
  step 'I navigate to Leads'
  on(NPSPLeadConvertPage) do |page|
    page.wait_until do
      page.recent_leads_section_element.visible? == true
    end
    expect(on(NPSPLeadConvertPage).recent_leads_section).to match 'No recent records'
  end
end
