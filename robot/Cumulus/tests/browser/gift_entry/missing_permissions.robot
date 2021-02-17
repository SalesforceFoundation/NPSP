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

Verify Permissions Error When Missing NPSP DI Batch Object Access
  # Change Object Permissions   remove  Form_Template__c  ${perm_set_name}
  Open Test Browser           useralias=${user_alias}                     
  Run Keyword And Continue On Failure   Go to Page                  Landing    ${NS}GE_Gift_Entry  default=permissions_error
  Run Keyword And Continue On Failure   Current Page Should Be      Landing    ${NS}GE_Gift_Entry  default=permissions_error
  Run Keyword And Continue On Failure   Page Should Contain         You must have permission to edit the following fields:
  # Change Object Permissions   add  Form_Template__c  Gift_Entry_Perms



# Verify Permissions Error When Missing Form Template Object Access


# Verify Permissions Error When DI Batch Description is Revoked


  

#Verify Permissions Error When Form Template Description is Revoked




