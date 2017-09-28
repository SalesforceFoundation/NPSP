Given(/^I create three Contacts "([^"]*)" and "([^"]*)" and "([^"]*)"$/) do |con1, con2, con3|
  create_contact_via_api(con1, con1 + 'street', con1 + 'city', con1 +'state', con1 + 'country', con1 + 'zip')
  @array_of_contacts << @contact_id
  create_contact_via_api(con2, con2 + 'street', con2 + 'city', con2 +'state', con2 + 'country', con2 + 'zip')
  @array_of_contacts << @contact_id
  create_contact_via_api(con3, con3 + 'street', con3 + 'city', con3 +'state', con3 + 'country', con3 + 'zip')
  @array_of_contacts << @contact_id
end

Given(/^I do a Contact Merge search for "([^"]*)"$/) do |search_term|
  on(NPSPContactMergePage) do |page|
    page.contact_search_box_element.hover
    page.contact_search_box_element.send_keys search_term
    page.contact_search_box_element.click
    sleep 1
    page.contact_search_button
  end
end

When(/^I select the second Contact as the winning Contact$/) do
  on(NPSPContactMergePage) do |page|
    page.contact_checkbox_first_element.when_present.click
    page.contact_checkbox_second_element.when_present.click
    page.contact_checkbox_third_element.when_present.click
    page.next_button_element.when_present.click
    page.choose_contact_second_element.when_present(10).click
  end
end

When(/^I merge the contacts$/) do
  on(NPSPContactMergePage) do |page|
    page.merge_contact_button_element.when_present(10).click
    page.modal_merge_button_element.when_present.click
    #page.merge_contact_button_element.when_present.click
  end

  step 'I navigate to Contacts'

  on(NPSPContactsPage) do |page|
    page.wait_until do
      page.all_contacts_element.visible? == true
    end
    page.all_contacts = 'All Contacts'
    page.go_button
    page.wait_until do
      page.contacts_display_element.visible?
    end
  end
end

When(/^I select details among the three Contact records$/) do
  on(NPSPContactMergePage) do |page|
    page.mailing_city1_element.when_present.click
    page.country3_element.click
    page.zip1_element.click
    page.state3_element.click
  end
end

Then(/^I should see the details captured in the resulting contact record$/) do
  on(NPSPContactsPage) do |page|
    page.merged_account
    page.wait_until do
      page.contact_data_element.visible? == true
    end
    expect(page.contact_data).to match /aaa2street.+aaa1city, aaa3state.+aaa1zip.+aaa3country/m
  end
end

Then(/^I should see "([^"]*)" in All Contacts$/) do |merged_contact|
  expect(on(NPSPContactsPage).contacts_display).to match merged_contact
end

Then(/^I should not see "([^"]*)" or "([^"]*)" in All Contacts$/) do |deleted1, deleted2|
  on(NPSPContactsPage) do |page|
    expect(page.contacts_display).not_to match deleted1
    expect(page.contacts_display).not_to match deleted2
  end
end
