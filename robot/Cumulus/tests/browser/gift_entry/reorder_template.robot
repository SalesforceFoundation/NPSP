*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/NPSPSettingsPageObject.py
...             robot/Cumulus/resources/GiftEntryPageObject.py
...             robot/Cumulus/resources/OpportunityPageObject.py
...             robot/Cumulus/resources/PaymentPageObject.py
Suite Setup     Run keywords
...             Open Test Browser
...             API Check And Enable Gift Entry
# ...             Setup Test Data
Suite Teardown  Capture Screenshot and Delete Records and Close Browser

*** Variables ***
${template}  Generated Template

*** Keywords ***


*** Test Cases ***

Reorder and Modify GE Template Fields
  [Documentation]                       This tests reordering, adding, and deleting sections
  ...                                   from the default GE template.

  [tags]                                unstable                    feature:GE          W-039563
  Go to Page                            Landing                     npsp__GE_Gift_Entry
  Click Link                            Templates
  Click Gift Entry Button               Create Template
  Current Page Should Be                Template                    GE_Gift_Entry
  Enter Value in Field
  ...                                   Template Name=${template}
  ...                                   Description=This is created by automation script 
  Click Gift Entry Button               Next: Form Fields

  #Adds 'Role' form field from the AccountSoftCredits section
  Perform Action On Object Field        select  AccountSoftCredits  Role

  Perform Action On Object Field        select  CustomObject1  CustomObject1Imported

  #Moves the CustomObject1Imported field up in the field order
  Click Gift Entry Button               button Up Data Import: CustomObject1Imported

  #Deletes the Payment: Check/Reference Number field from the template
  Click Gift Entry Button               button Delete Payment: Check/Reference Number
  Verify Template Builder               conains  AccountSoftCredits: Role
  Verify Template Builder               does not contain  Payment: Check/Reference Number
  Sleep                                 3s
  #Click Gift Entry Button               Save & Close
  #Current Page Should Be                Landing                     npsp__GE_Gift_Entry
  #Click Gift Entry Button               New Batch
  #Select Template                       ${template}


 
