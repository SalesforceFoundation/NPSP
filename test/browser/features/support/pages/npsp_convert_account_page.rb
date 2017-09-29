class NPSPAccountConvertPage
  include PageObject

  select_list(:account_field, name: /HHId/)
  button(:begin_conversion, id: 'conversionBTN')

  span(:all_non_npsp, text: 'All non-NPSP apps have been temporarily uninstalled or disabled.')
  span(:all_record, text: 'All record ownership has been transferred from any inactive users.')
  span(:all_required, text: 'All required field restrictions for custom fields have been removed.')
  span(:all_users, text: 'All users have logged out of my Salesforce instance.')
  span(:all_workflows, text: 'All workflows and any custom validation rules have been disabled.')
  span(:duplication_management, text: 'All Data.com Duplication Management Rules have been disabled.')
  span(:i_accept, text: 'I accept the risk associated with using this tool, including data loss and inconsistent data.')
  span(:i_am_aware, text: 'I am aware this tool will only work for Contacts that currently have a Household associated.')
  span(:ive_consulted, text: "I've consulted with my local Salesforce expert.")
  span(:my_data, text: 'My data has been backed-up by going to Setup | Data Management | Export Data')
  span(:the_conversion, text: 'The conversion process has been tested in a fresh sandbox.')
end
