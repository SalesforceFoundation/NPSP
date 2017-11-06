Then(/^I should see the Getting Started text$/) do
  on(NPSPGettingStartedPage) do |page|
    expect(page.page_contents).to match 'Welcome to Salesforce and the Nonprofit Success Pack!'
    expect(page.page_contents).to match /Get Started.+Review Salesforce Fundamentals.+Get Started with the Nonprofit Success Pack.+Nonprofit Success Pack Trail.+NPSP Admin Guide to Importing Donor Data/m
    expect(page.page_contents).to match /Get Help.+Power of Us Hub Community.+Salesforce Success Plan.+Salesforce\.org Office Hours/m
  end
end

Then(/^I should see the Getting Started links$/) do
  on(NPSPGettingStartedPage) do |page|
    expect(page.salesforce_fundamentals_link_element.visible?).to be(true)
    expect(page.beginner_admin_trail_link_element.visible?).to be(true)
    expect(page.this_interactive_learning_path_link_element.visible?).to be(true)
    expect(page.guide_link_element.visible?).to be(true)
    expect(page.power_of_us_login_link_element.visible?).to be(true)
    expect(page.salesforce_success_learn_more_link_element.visible?).to be(true)
    expect(page.foundation_office_hours_learn_more_link_element.visible?).to be(true)
  end
end
