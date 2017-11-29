When(/^I fill in EPT information$/) do
  on(EPTPage).template_name_element.when_present.send_keys("ept" + @random_string)
end

When(/^I create a Task and a Subtask$/) do
  on(EPTPage) do |page|
    page.new_task_button
    page.task_subject_element.when_present.send_keys('top subject' + @random_string)
    page.days_after_element.send_keys '8'
    page.dependent_task_button_element.when_present.click
    page.subtask_subject_element.when_present.send_keys('subtask subject' + @random_string)
  end
end

When(/^I save my EPT$/) do
  on(EPTPage).save_button_element.click
end

Then(/^my EPT should exist$/) do
  on(EPTPage) do |page|
    page.saved_page_header_element.when_present(10)
    expect(page.saved_page_header).to eq ('ept' + @random_string)
    expect(page.task_link_element.text).to eq ('top subject' + @random_string)
    expect(page.subtask_link_element.text).to eq ('subtask subject' + @random_string)
  end
end
