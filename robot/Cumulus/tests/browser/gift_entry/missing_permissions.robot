*** Settings ***
Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/GiftEntryPageObject.py
Suite Setup     Run keywords
...             Open Test Browser  alias=original
...             AND  Setup Test Data
...             AND  API Check And Enable Gift Entry
...             AND  Close All Browsers
Suite Teardown  Run Keywords
...             Capture Screenshot and Delete Records and Close Browser

*** Variables ***
${perm_set_name} =  Gift_Entry_Perms
${user_alias} =     permtest
${di_batch} =       DataImportBatch__c
${form_temp} =      Form_Template__c

*** Keywords ***

Setup Test Data

  ${NS} =  Get NPSP Namespace Prefix
  Set Suite Variable  ${NS}


*** Test Cases ***

#   Note: This test uses the 'sysadmin_test' profile, the 'permtest' user,
#   and the 'Gift_Entry_Perms' permission set that is created during org setup. 
#   These are only used in this test to ensure self-containment of the data changes.

Verify Permissions Error When Missing Form Template Object Access
  [Documentation]          Disables object permissions for the Form Template Object in the Gift_Entry_Perms permission set,
  ...                      navigates to the Gift Entry app to verify the permissions error message, then re-adds the object
  ...                      permissions and reloads the Gift Entry app to verify the permissions error no longer displays.
  [tags]                   unstable      feature:GE        W-8279499
  [Teardown]               Run Keywords  Object Permissions Cleanup  ${NS}${form_temp}  ${perm_set_name}
  ...                      AND  Delete All Cookies
  ...                      AND  Close All Browsers

  Open Test Browser           alias=otherone  useralias=${user_alias}
  Change Object Permissions   remove  ${NS}${form_temp}  ${perm_set_name}       
  Go to Page                  Landing    GE_Gift_Entry  default=permissions_error
  Current Page Should Be      Landing    GE_Gift_Entry  default=permissions_error
  Page Should Contain         You must have permission to edit the following fields: ${NS}${di_batch}: (${NS}${form_temp})
  Change Object Permissions   add  ${NS}${form_temp}  ${perm_set_name}
  Reload Page
  Page Should Not Contain     You must have permission to edit the following fields: ${NS}${di_batch}: (${NS}${form_temp})


Verify Permissions Error When Missing NPSP DI Batch Object Access
  [Documentation]          Disables object permissions for the NPSP Data Import Batch Object in the Gift_Entry_Perms permission set,
  ...                      navigates to the Gift Entry app to verify the permissions error message, then re-adds the object
  ...                      permissions and reloads the Gift Entry app to verify the permissions error no longer displays.
  [tags]                   unstable      feature:GE        W-8279499
  [Teardown]               Run Keywords  Object Permissions Cleanup  ${NS}${di_batch}  ${perm_set_name}
  ...                      AND  Delete All Cookies
  ...                      AND  Close All Browsers

  Change Object Permissions   remove  ${NS}${di_batch}  ${perm_set_name}
  Open Test Browser           alias=othertwo  useralias=${user_alias}                     
  Go to Page                  Landing    GE_Gift_Entry  default=permissions_error
  Current Page Should Be      Landing    GE_Gift_Entry  default=permissions_error
  Page Should Contain         You must have permission to edit the following objects: ${NS}${di_batch}      
  Change Object Permissions   add  ${NS}${di_batch}  ${perm_set_name}
  Reload Page
  Page Should Not Contain     You must have permission to edit the following objects: ${NS}${di_batch}


Verify Permissions Error When DI Batch Description Field Access is Revoked
  [Documentation]          Disables field permissions for the Data Import Batch Description field in the Gift_Entry_Perms permission set,
  ...                      navigates to the Gift Entry app to verify the permissions error message, then re-adds the object
  ...                      permissions and reloads the Gift Entry app to verify the permissions error no longer displays.
  [tags]                   unstable      feature:GE        W-8279499
  [Teardown]               Run Keywords  Field Permissions Cleanup  ${NS}${di_batch}  ${NS}${field}  ${perm_set_name}
  ...                      AND  Delete All Cookies
  ...                      AND  Close All Browsers

  ${field}  Set Variable      Batch_Description__c
  Change Field Permissions    remove  ${NS}${di_batch}  ${NS}${field}  ${perm_set_name}
  Open Test Browser           alias=otherthree  useralias=${user_alias}                     
  Go to Page                  Landing    GE_Gift_Entry  default=permissions_error
  Current Page Should Be      Landing    GE_Gift_Entry  default=permissions_error
  Page Should Contain         You must have permission to edit the following fields: ${NS}${di_batch}: (${NS}${field})      
  Change Field Permissions    add  ${NS}${di_batch}  ${NS}${field}  ${perm_set_name}
  Reload Page
  Page Should Not Contain     You must have permission to edit the following fields: ${NS}${di_batch}: (${NS}${field})


Verify Permissions Error When Form Template Description Field Access is Revoked
  [Documentation]          Disables field permissions for the Description field of the Form Template Object in the Gift_Entry_Perms permission set,
  ...                      navigates to the Gift Entry app to verify the permissions error message, then re-adds the object
  ...                      permissions and reloads the Gift Entry app to verify the permissions error no longer displays.
  [tags]                   unstable      feature:GE        W-8279499
  [Teardown]               Run Keywords  Field Permissions Cleanup  ${NS}${form_temp}  ${NS}${field}  ${perm_set_name}
  ...                      AND  Delete All Cookies
  ...                      AND  Close All Browsers

  ${field}  Set Variable      Description__c
  Change Field Permissions    remove  ${NS}${form_temp}  ${NS}${field}  ${perm_set_name}
  Open Test Browser           alias=otherfour  useralias=${user_alias}                     
  Go to Page                  Landing    GE_Gift_Entry
  Current Page Should Be      Landing    GE_Gift_Entry
  Click Link                  Templates
  Page Should Contain         You must have permission to edit the following fields: ${NS}${form_temp}: (${NS}${field})      
  Change Field Permissions    add  ${NS}${form_temp}  ${NS}${field}  ${perm_set_name}
  Reload Page
  Click Link                  Templates
  Page Should Not Contain     You must have permission to edit the following fields: ${NS}${form_temp}: (${NS}${field})


Verify Target Object Field Without Access Displays Permissions Errors
  [Documentation]          Disables object permissions for the Check/Reference field in the custom Payment
  ...                      Object in the Gift_Entry_Perms permission set, then navigates to the GE form to validate that
  ...                      the permissions error displays on the page. The test then navigates to the Template Builder to
  ...                      verify that the error messages display for the fields without access. Then, permissions are
  ...                      restored to the field, and then the test navigates back to the GE form, and then to the Template
  ...                      Builder to ensure the permissions error messages no longer display.
  [tags]                   unstable      feature:GE        W-8279499
  [Teardown]               Run Keywords  Field Permissions Cleanup  ${obj}  ${field}  ${perm_set_name}
  ...                      AND  Delete All Cookies
  ...                      AND  Close All Browsers

  ${obj}    Set Variable       npe01__OppPayment__c
  ${field}  Set Variable       npe01__Check_Reference_Number__c
  Change Field Permissions     remove  ${obj}  ${field}  ${perm_set_name} 
  Open Test Browser            alias=otherfive  useralias=${user_alias}
  Go to Page                   Landing    GE_Gift_Entry
  Current Page Should Be       Landing    GE_Gift_Entry
  Click Gift Entry Button      New Single Gift
  Page Should Contain          You must have permission to edit the following fields: ${obj}: (${field})
  Go to Page                   Landing    GE_Gift_Entry
  Current Page Should Be       Landing    GE_Gift_Entry
  Reload Page
  Wait Until Page Contains     Templates
  Click Link                   Templates
  Wait Until Page Contains     Default Gift Entry Template
  Select Template Action       Default Gift Entry Template   Edit
  Current Page Should Be       Template                      GE_Gift_Entry
  Wait Until Page Contains     Gift Entry Template Information
  Click Gift Entry Button      Next: Form Fields
  Wait Until Page Contains Element   npsp:gift_entry.page_error
  Page Should Contain          This form contains fields that can't be found. Please check with your administrator.
  Page Should Contain Element  npsp:gift_entry.field_error:Check/Reference Number,Field not found
  Change Field Permissions     add  ${obj}  ${field}  ${perm_set_name}
  Go to Page                   Landing    GE_Gift_Entry
  Current Page Should Be       Landing    GE_Gift_Entry
  Click Gift Entry Button      New Single Gift
  Page Should Not Contain      You must have permission to edit the following fields: ${obj}: (${field})     
  Go to Page                   Landing    GE_Gift_Entry
  Current Page Should Be       Landing    GE_Gift_Entry
  Reload Page
  Wait Until Page Contains     Templates
  Click Link                   Templates
  Select Template Action       Default Gift Entry Template   Edit
  Current Page Should Be       Template                      GE_Gift_Entry
  Click Gift Entry Button      Next: Form Fields
  Page Should Not Contain      This form contains fields that can't be found. Please check with your administrator.
  Page Should Not Contain Element  npsp:gift_entry.field_error:Check/Reference Number,Field not found
