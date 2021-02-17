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
...             Close All Browsers

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




