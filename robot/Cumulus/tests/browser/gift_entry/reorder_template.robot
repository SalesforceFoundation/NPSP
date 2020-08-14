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
${placeholder}  yes

*** Keywords ***


*** Test Cases ***

Reorder and Modify GE Template Fields
  [Documentation]                       This tests reordering, adding, and deleting sections
  ...                                   from the default GE template.

  [tags]                                unstable                    feature:GE          W-039563
  Go to Page                            Landing                      npsp__GE_Gift_Entry
  Click Link                            Templates
  Select Template Action                Default Gift Entry Template  Edit
  Click Gift Entry Button               Next: Form Fields
  Perform Action On Object Field        select  AccountSoftCredits  Role

  #Moves the CustomObject1Imported field up in the field order
  Click Gift Entry Button               button Up Data Import: CustomObject1Imported

  #Deletes the Delete Payment: Check/Reference Number field from the template
  Click Gift Entry Button               button Delete Payment: Check/Reference Number

  Sleep                                 3s
