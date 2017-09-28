class NPSPErrorSettingsPage
  include PageObject

  checkbox(:store_errors, id: /cbxSEO/)
  checkbox(:error_notifications, id: /cbxENO/)
  checkbox(:page_store_errors_saved, id: /cbxSEOO/, disabled: 'disabled')
  checkbox(:page_error_notifications_saved, id: /cbxENOO/, disabled: 'disabled')
end
