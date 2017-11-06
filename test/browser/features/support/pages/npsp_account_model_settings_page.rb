class NPSPAccountModelSettingsPage
  include PageObject

  select_list(:account_model_select, name: /slAP/)
  span(:changed_account_model, text: 'Organization')
  select_list(:household_account_record_type, name: /slHHAR/)
  select_list(:one_to_one_record_type, name: /slOORT/)
  button(:save_button, id: /saveCon/)
  button(:edit_button, id: /editCon/)
end
