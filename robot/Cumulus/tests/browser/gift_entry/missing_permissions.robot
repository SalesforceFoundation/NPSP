*** Settings ***
Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/GiftEntryPageObject.py
Suite Setup     Run keywords
...             Open Test Browser
...             Setup Test Data
...             API Check And Enable Gift Entry
Suite Teardown  Run Keywords
...             Capture Screenshot and Delete Records and Close Browser

*** Variables ***
${perm_set_name} =  Gift_Entry_Perms
${user_alias} =     permtest

*** Keywords ***

Setup Test Data

  ${NS} =  Get NPSP Namespace Prefix
  Set Suite Variable  ${NS}

*** Test Cases ***

Verify Permissions Error When Missing Form Template Object Access
  [Documentation]          Disables object permissions for the Form Template Object in the Gift_Entry_Perms permission set,
  ...                      navigates to the Gift Entry app to verify the permissions error message, then re-adds the object
  ...                      permissions and reloads the Gift Entry app to verify the permissions error no longer displays.
  [tags]                   unstable      feature:GE        W-8279499

  ${obj}    Set Variable   Form_Template__c
  Change Object Permissions   remove  ${obj}  ${perm_set_name}
  Open Test Browser           useralias=${user_alias}          
  Go to Page                  Landing    GE_Gift_Entry  default=permissions_error
  Current Page Should Be      Landing    GE_Gift_Entry  default=permissions_error
  Run Keyword And Continue On Failure   Page Should Contain  You must have permission to edit the following fields: ${NS}DataImportBatch__c: (${NS}${obj})
  Change Object Permissions   add  ${obj}  ${perm_set_name}
  Reload Page
  Page Should Not Contain     You must have permission to edit the following fields: ${NS}DataImportBatch__c: (${NS}${obj})
  Delete All Cookies
  Close All Browsers

Verify Permissions Error When Missing NPSP DI Batch Object Access
  [Documentation]          Disables object permissions for the NPSP Data Import Batch Object in the Gift_Entry_Perms permission set,
  ...                      navigates to the Gift Entry app to verify the permissions error message, then re-adds the object
  ...                      permissions and reloads the Gift Entry app to verify the permissions error no longer displays.
  [tags]                   unstable      feature:GE        W-8279499

  ${obj}    Set Variable   DataImportBatch__c
  Change Object Permissions   remove  ${obj}  ${perm_set_name}
  Open Test Browser           useralias=${user_alias}                     
  Go to Page                  Landing    GE_Gift_Entry  default=permissions_error
  Current Page Should Be      Landing    GE_Gift_Entry  default=permissions_error
  Run Keyword And Continue On Failure   Page Should Contain  You must have permission to edit the following objects: ${NS}${obj}       
  Change Object Permissions   add  ${obj}  ${perm_set_name}
  Reload Page
  Page Should Not Contain     You must have permission to edit the following objects: ${NS}${obj}
  Delete All Cookies
  Close All Browsers

Verify Permissions Error When DI Batch Description Field Access is Revoked
  [Documentation]          Disables field permissions for the Data Import Batch Description field in the Gift_Entry_Perms permission set,
  ...                      navigates to the Gift Entry app to verify the permissions error message, then re-adds the object
  ...                      permissions and reloads the Gift Entry app to verify the permissions error no longer displays.
  [tags]                   unstable      feature:GE        W-8279499

  ${obj}  Set Variable  DataImportBatch__c
  ${field}  Set Variable   Batch_Description__c
  Change Field Permissions   remove  ${obj}  ${field}  ${perm_set_name}
  Open Test Browser           useralias=${user_alias}                     
  Go to Page                  Landing    GE_Gift_Entry  default=permissions_error
  Current Page Should Be      Landing    GE_Gift_Entry  default=permissions_error
  Run Keyword And Continue On Failure   Page Should Contain  You must have permission to edit the following fields: ${NS}${obj}: (${NS}${field})      
  Change Field Permissions    add  ${obj}  ${field}  ${perm_set_name}
  Reload Page
  Page Should Not Contain     You must have permission to edit the following fields: ${NS}${obj}: (${NS}${field})
  Delete All Cookies
  Close All Browsers

Verify Permissions Error When Form Template Description Field Access is Revoked
  [Documentation]          Disables field permissions for the Description field of the Form Template Object in the Gift_Entry_Perms permission set,
  ...                      navigates to the Gift Entry app to verify the permissions error message, then re-adds the object
  ...                      permissions and reloads the Gift Entry app to verify the permissions error no longer displays.
  [tags]                   unstable      feature:GE        W-8279499

  ${obj}    Set Variable     Form_Template__c
  ${field}  Set Variable      Description__c
  Change Field Permissions   remove  ${obj}  ${field}  ${perm_set_name}
  Open Test Browser           useralias=${user_alias}                     
  Go to Page                  Landing    GE_Gift_Entry
  Current Page Should Be      Landing    GE_Gift_Entry
  Click Link                  Templates
  Run Keyword And Continue On Failure   Page Should Contain  You must have permission to edit the following fields: ${NS}${obj}: (${NS}${field})      
  Change Field Permissions   add  ${obj}  ${field}  ${perm_set_name}
  Reload Page
  Click Link                  Templates
  Page Should Not Contain     You must have permission to edit the following fields: ${NS}${obj}: (${NS}${field})
  Delete All Cookies 
  Close All Browsers

Verify Target Object Field Without Access Does Not Render in GE Form
  [Documentation]          Disables object permissions for the Check/Reference field in the custom Payment
  ...                      Object in the Gift_Entry_Perms permission set, then navigates to the GE form to validate that
  ...                      the permissions error displays on the page. The test then navigates to the Template Builder to
  ...                      verify that the error messages display for the fields without access. Then, permissions are
  ...                      restored to the field, and then the test navigates back to the GE form, and then to the Template
  ...                      Builder to ensure the permissions error messages no longer display.
  [tags]                   unstable      feature:GE        W-8279499
  ${obj}    Set Variable     npe01__OppPayment__c
  ${field}  Set Variable   npe01__Check_Reference_Number__c
  Change Field Permissions     remove  ${obj}  ${field}  ${perm_set_name} 
  Open Test Browser            useralias=${user_alias}
  Go to Page                   Landing    GE_Gift_Entry
  Click Gift Entry Button      New Single Gift
  Run Keyword And Continue On Failure    Page Should Contain  You must have permission to edit the following fields: ${NS}${obj}: (${NS}${field})
  Go to Page                   Landing    GE_Gift_Entry
  Current Page Should Be       Landing    GE_Gift_Entry
  Click Link                   Templates
  Select Template Action       Default Gift Entry Template   Edit
  Current Page Should Be       Template                      GE_Gift_Entry
  Click Gift Entry Button      Next: Form Fields
  Wait Until Page Contains Element   npsp:gift_entry.page_error
  Page Should Contain          This form contains fields that can't be found. Please check with your administrator.
  Page Should Contain Element  npsp:gift_entry.field_error:Check/Reference Number,Field not found
  Change Field Permissions     add  ${obj}  ${field}  ${perm_set_name}
  Go to Page                   Landing    GE_Gift_Entry
  Current Page Should Be       Landing    GE_Gift_Entry
  Click Gift Entry Button      New Single Gift
  Page Should Not Contain      You must have permission to edit the following fields: ${NS}${obj}: (${NS}${field})     
  Go to Page                   Landing    GE_Gift_Entry
  Current Page Should Be      Landing    GE_Gift_Entry
  Click Link                   Templates
  Select Template Action       Default Gift Entry Template   Edit
  Current Page Should Be       Template                      GE_Gift_Entry
  Click Gift Entry Button      Next: Form Fields
  Page Should Not Contain          This form contains fields that can't be found. Please check with your administrator.
  Page Should Not Contain Element  npsp:gift_entry.field_error:Check/Reference Number,Field not found
  Delete All Cookies
  Close All Browsers

