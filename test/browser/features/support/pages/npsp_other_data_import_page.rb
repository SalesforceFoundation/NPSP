class NPSPOtherDataImportPage
  include PageObject

  button(:go_button, name: 'go')
  button(:new_button, title: 'New')
  div(:page_info, class: 'bPageTitle')
  button(:start_data_import_button, name: 'npsp__process_data_import')
end
