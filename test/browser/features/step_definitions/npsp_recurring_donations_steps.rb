When(/^I click Refresh Opportunities$/) do
  on(NPSPRecurringDonationsPage).refresh_button_element.when_present.click
end

When(/^I create a "([^"]*)" recurring donation for "([^"]*)" months for "([^"]*)"$/) do |period, number, amount|
  create_contact_via_api('arecurringdonation' + @random_string)
  on(NPSPRecurringDonationsPage) do |page|
    page.new_button_element.when_present.click
    page.donation_name_element.when_present.send_keys @random_string
    page.period_select = period
    page.installments_field = number
    page.amount = amount
    page.contact_field = 'arecurringdonation' + @random_string
    page.save_button
  end
end

When(/^I delete two of the payments$/) do
  on(NPSPRecurringDonationsPage) do |page|
    page.wait_until do
      page.delete_link_element.when_present(20)
    end
    page.delete_link
    @browser.alert.ok
    page.wait_until do
      page.delete_link_element.when_present(20)
    end
    page.delete_link
    @browser.alert.ok
  end
end

Then(/^I should see "([^"]*)" monthly donations for "([^"]*)"$/) do |number, amount|
  on(NPSPRecurringDonationsPage) do |page|
    page.wait_until(15) do
      page.donations_section_element.when_present
      !page.donations_section.match ('Loading')
    end
    expect(page.donations_section). to match /#{@random_string} Donation \(1 of 12\).+Pledged /
    expect(page.donations_section). to match Regexp.escape(amount)
  end
end
