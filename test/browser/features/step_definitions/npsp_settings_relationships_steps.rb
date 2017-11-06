
When(/^I change Relationships Affiliations settings$/) do
  on(NPSPRelationshipsSettingsPage).unsaved_page_affiliations_element.when_present

  on(NPSPSettingsPage).edit_aff_button_element.when_present.click
  step 'I wait for the page to revert'

  on(NPSPRelationshipsSettingsPage) do |page|
    page.wait_until do
      page.affiliations_checkbox_element.disabled? == false
    end
    page.uncheck_affiliations_checkbox
  end

end

When(/^I change Relationships Reciprocal Method settings$/) do
  on(NPSPRelationshipsSettingsPage).unsaved_page_reciprocal_method_element.when_present

  on(NPSPSettingsPage).edit_rel_button_element.when_present.click
  step 'I wait for the page to revert'

  on(NPSPRelationshipsSettingsPage) do |page|
    page.reciprocal_method_select_element.when_present(15)
    page.reciprocal_method_select='Value Inversion'
  end

end

When(/^I click Save Relationships Settings$/) do
  api_client do
    @these_settings = select_api 'select Id,
                                          Name,
                                          Reciprocal_Method
                                          from Relationship_Settings'
    end

    @these_settings = @these_settings.first

  sleep 1
  on(NPSPRecurringDonationsSettingsPage).save_button
end

When(/^I click Save Relationships Affiliations Settings$/) do
  api_client do
    @these_settings = select_api 'select Id,
                                          Name,
                                          Automatic_Affiliation_Creation_Turned_On
                                          from Affiliations_Settings'
  end

  @these_settings = @these_settings.first

  sleep 1 #API CALL NEEDS TO PROPAGATE BEFORE CLICKING SAVE BUTTON
  on(NPSPRecurringDonationsSettingsPage).save_button_element.click
end

Then(/^Relationships settings should be saved$/) do
  on(NPSPRelationshipsSettingsPage) do |page|
    page.page_reciprocal_method_element.when_present(30)
    expect(page.page_reciprocal_method_element.visible?).to be(true)
  end
end

Then(/^Relationships Affiliations settings should be saved$/) do
  on(NPSPRelationshipsSettingsPage) do |page|
    page.saved_page_affiliations_element.when_present(30)
    expect(page.saved_page_affiliations_element.when_present.visible?).to be(true)
  end
end

Then(/^when I refresh the Relationships Affiliations page my changes should be visible$/) do
  @browser.refresh
  step 'I navigate to Relationships Affiliations'
  step 'Relationships Affiliations settings should be saved'
end

Then(/^when I refresh the Relationships Relationships page my changes should be visible$/) do
  @browser.refresh
  step 'I navigate to Relationships Relationships'
  step 'Relationships settings should be saved'
end
