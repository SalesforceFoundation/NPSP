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
  Change Object Permissions   remove  Form_Template__c  ${perm_set_name}
  Open Test Browser           useralias=${user_alias}                     
  Go to Page                  Landing    ${NS}GE_Gift_Entry  default=permissions_error
  Current Page Should Be      Landing    ${NS}GE_Gift_Entry  default=permissions_error
  #Note: The test below is returning an incorrect error message.
  Run Keyword And Continue On Failure   Page Should Contain         You must have permission to edit the following fields:
  Change Object Permissions   add  Form_Template__c  ${perm_set_name}
  Close All Browsers

Verify Permissions Error When Missing NPSP DI Batch Object Access
  Change Object Permissions   remove  DataImportBatch__c  ${perm_set_name}
  Open Test Browser           useralias=${user_alias}                     
  Go to Page                  Landing    ${NS}GE_Gift_Entry  default=permissions_error
  Current Page Should Be      Landing    ${NS}GE_Gift_Entry  default=permissions_error
  Run Keyword And Continue On Failure   Page Should Contain  You must have permission to edit the following objects: ${NS}DataImportBatch__c       
  Change Object Permissions   add  DataImportBatch__c  ${perm_set_name}
  Close All Browsers

Verify Permissions Error When DI Batch Description Field Access is Revoked
  ${obj}  Set Variable  DataImportBatch__c
  ${field}  Set Variable   Batch_Description__c
  Change Field Permissions   remove  ${obj}  ${field}  ${perm_set_name}
  Open Test Browser           useralias=${user_alias}                     
  Go to Page                  Landing    ${NS}GE_Gift_Entry  default=permissions_error
  Current Page Should Be      Landing    ${NS}GE_Gift_Entry  default=permissions_error
  Run Keyword And Continue On Failure   Page Should Contain  You must have permission to edit the following fields: ${NS}${obj}: (${NS}${field})      
  Change Field Permissions   add  ${obj}  ${field}  ${perm_set_name}
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
  Close All Browsers


