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
# &{method}         Default Value=Check
# &{check}          Default Value=abc11233
# &{date_default}   Default Value=Today
# &{custom}         Required=checked
# ${amount}         50
# ${msg}            Automation test

*** Keywords ***


*** Test Cases ***

Reorder and Modify GE Template Fields
  [Documentation]                       This tests reordering, adding, and deleting sections
  ...                                   from the default GE template.

  [tags]                                unstable                    feature:GE          W-039563
  Go to Page                            Landing                      npsp__GE_Gift_Entry
  Click Link                            Templates
  Select Template Action                Default Gift Entry Template  Edit
  Click Gift Entry Button
