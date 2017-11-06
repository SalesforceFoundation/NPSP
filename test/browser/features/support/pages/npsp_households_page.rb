class NPSPHouseholdsSettingsPage
  include PageObject

  checkbox(:automatic_hh_naming, id: /cbxAHN/)
  div(:example_text_box, class: 'sectionExamples')
  select(:formal_greetimg_format, name: /slstrFormatFG/)
  select(:hh_creation_excluded, name: /idDBMS/)
  select(:hh_name_format, name: /slstrFormatHH/)
  span(:page_name_format_saved, text: "{!{!FirstName}} {!LastName} Household")
  select(:hh_obj_rule, name: /slHR/)
  div(:hh_page_contents, id: /idPanelHH/)
  text_field(:implementing_class, name: /txtClass/)
  select(:informal_greetimg_format, name: /slstrFormatIG/)
  select(:mail_list_report, name: /slHMLI/)
  text_field(:name_connector, name: /txtAnd/)
  text_field(:name_overrun, name: /txtOverrun/)
  div(:page_contents, class: /content/)
  text_field(:contact_overrun, name: /txtOverrunCount/)
end