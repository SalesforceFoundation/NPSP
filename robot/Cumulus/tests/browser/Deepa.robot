*** Settings ***
Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/ContactPageObject.py
...             robot/Cumulus/resources/GiftEntryPageObject.py

Suite Setup     Open Test Browser
Suite Teardown  Close all browsers

*** Variables ***
${BROWSER}  chrome
${first_name}   deepa
${last_name}    mehta

*** Test Cases ***
#Example browser test
  #  Go to Page            Listing               Contact 
  #  Click Object Button                   New
  #  Wait For Modal                        New                                   Contact
   # Populate Modal Form
  #  ...                                   First Name=${first_name}
   # ...                                   Last Name=${last_name}
   # Click Modal Button                    Save
  #  Wait Until Modal Is Closed
  #  Current Page Should Be                Details                               Contact

Create New Gift
    Go To Page                                 Landing              GE_Gift_Entry
    Click Gift Entry Button                                New Single Gift
   