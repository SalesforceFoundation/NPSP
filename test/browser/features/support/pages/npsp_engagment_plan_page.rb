class EPTPage
  include PageObject

  text_field(:template_name, id: /theForm:idName/)
  button(:new_task_button, value: 'Add Task')
  button(:dependent_task_button, css: 'button.slds-button:nth-child(1)')
  button(:save_button, id: /:saveBTN/m )
  h2(:saved_page_header, class: 'pageDescription')
  a(:task_link, text: /top subject/)
  a(:subtask_link, text: /subtask subject/)
  text_field(:task_subject, id: /inputX/)
  text_field(:days_after, id: /inputX/, index: 2)
  text_field(:subtask_subject, id: /inputX/, index: 3)
end
