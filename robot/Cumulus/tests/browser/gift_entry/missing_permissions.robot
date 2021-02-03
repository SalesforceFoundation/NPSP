*** Settings ***
Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/GiftEntryPageObject.py
Suite Setup     Run keywords
...             Open Test Browser
...             Setup Test Data
...             API Check And Enable Gift Entry
Suite Teardown  Run Keywords
...             Capture Screenshot and Delete Session Records and Delete Records and Close Browser

*** Variables ***
${ns} =            Get NPSP Namespace Prefix
${profile_name} =  Generate Random String

*** Keywords ***

Setup Test Data

  &{PROFILE_DATA} =  API Query Record  ${ns}Profile  Name=System Administrator
  Set Suite Variable  &{PROFILE_DATA}

  &{CLONED_SYSADMIN_RECORD} =  Salesforce Insert  ${ns}Profile  
  ...       Name=${profile_name} 
  ...       &{PROFILE_DATA}

  &{USER} =  Salesforce Insert  User
  ...       FirstName=Test
  ...       LastName=User

*** Test Cases ***

# Verify Permissions Error When Missing NPSP DI Batch Object Access

# Verify Permissions Error When Missing Form Template Object Access





