Before do |scenario|
  @array_of_contacts = []
  @array_of_contact_names = []
  @array_of_gaus = []
  @array_of_opp_ids = []
  @gau_names = []
  set_url_and_object_namespace_to_npsp
  # OPEN THE ALL TABS PAGE BEFORE ANYTHING ELSE SO THAT navigation_steps.rb WILL ALWAYS WORK
  # SOMETIMES THE BROWSER DOESN'T DO THIS WITHOUT A PAUSE FIRST
  sleep 2
  @browser.goto($instance_url + '/home/showAllTabs.jsp')
end

After('@reset_these_settings') do
  reset_these_settings(@these_settings)
end

After do |scenario|
  #CLOBBER OBJECTS TO PREVENT FAILURES FROM POLLUTING DOWNSTREAM TESTS
  #IF THE OBJECT IS ALREADY DELETED THIS IS A NOOP
  # update_account_model('Household Account')
  delete_contacts_via_api
  delete_leads
  delete_payments
  delete_opportunities
  delete_recurring_donations
  delete_household_accounts
  delete_non_household_accounts
  delete_household_objects
  delete_gaus_via_api
  delete_engagement_plan_templates
end
