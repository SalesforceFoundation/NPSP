When(/^I create a new Opportunity with name "([^"]*)" and close date today and amount "([^"]*)" and stage "([^"]*)"$/) do |name, amount, stage|
  step 'I create a new random account via the API'
  on(NPSPOpportunitiesPage) do |page|
    page.wait_until do
      page.new_button_element.visible? == true
    end
    page.new_button
    page.wait_until do
      page.today_link_element.visible? == true
    end
    page.today_link
    page.account_name = "aaaacreacc1#{@random_string}"
    page.opp_name = name + @random_string
    page.opp_amount = amount
    page.opp_stage = "Closed Won"
    page.save_button
    page.wait_until do
      page.opp_stage_element.exist? == false
    end
  end
end

When(/^I navigate from Opportunity to the Payment$/) do
  @browser.goto($instance_url + '/home/showAllTabs.jsp')
  step 'I navigate to Payments'
  on(NPSPOpportunitiesPage) do |page|
    page.go_button
    page.wait_until do
      page.payment_edit_link_element.visible? == true
    end
    #page.payment_edit_link
    page.payment_page_link_element.when_present.click
  end
end
