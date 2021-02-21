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
  Open Test Browser           wait=False  useralias=${user_alias}          
  Go to Page                  Landing    GE_Gift_Entry  default=permissions_error
  Current Page Should Be      Landing    GE_Gift_Entry  default=permissions_error
  Run Keyword And Continue On Failure   Page Should Contain  You must have permission to edit the following fields: ${NS}DataImportBatch__c: (${NS}${obj})
  Change Object Permissions   add  ${obj}  ${perm_set_name}
  Reload Page
  Page Should Not Contain     You must have permission to edit the following fields: ${NS}DataImportBatch__c: (${NS}${obj})
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
  Page Should Not Contain     You must have permission to edit the following objects: ${NS}${obj}
  Close All Browsers


Verify Permissions Error When Form Template Description Field Access is Revoked
  ${obj}  Set Variable  Form_Template__c
  ${field}  Set Variable   Description__c
  Change Field Permissions   remove  ${obj}  ${field}  ${perm_set_name}
  Open Test Browser           useralias=${user_alias}                     
  Go to Page                  Landing    ${NS}GE_Gift_Entry
  Current Page Should Be      Landing    ${NS}GE_Gift_Entry
  Click Link                  Templates
  Run Keyword And Continue On Failure   Page Should Contain  You must have permission to edit the following fields: ${NS}${obj}: (${NS}${field})      
  Change Field Permissions   add  ${obj}  ${field}  ${perm_set_name}
  Reload Page
  Click Link                  Templates
  Page Should Not Contain     You must have permission to edit the following fields: ${NS}${obj}: (${NS}${field}) 
  Close All Browsers

# Verify Field Without Access Does Not Render in GE Form
#   ${obj}  Set Variable  
#   ${field}  Set Variable   
#   Change Field Permissions   remove  ${obj}  ${field}  ${perm_set_name}
#   Open Test Browser           useralias=${user_alias}  


