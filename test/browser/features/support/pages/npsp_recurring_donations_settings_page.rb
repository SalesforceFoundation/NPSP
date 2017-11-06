class NPSPRecurringDonationsSettingsPage
  include PageObject

  text_field(:opp_forecast_months, value: '12')
  select_list(:opp_behavior, id: /slOOB/)
  button(:save_button, value: 'Save')
  span(:page_opp_forecast_months_saved, text: '24')
  span(:page_opp_behavior, text: 'Mark_Opportunities_Closed_Lost')
  span(:page_opp_behavior_saved, text: 'Delete_Open_Opportunities')
end
