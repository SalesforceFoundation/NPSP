*** Settings ***
Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/AccountPageObject.py
...             robot/Cumulus/resources/NPSP.py



Suite Setup     Open Test Browser
Suite Teardown  Close all browsers

*** Variables ***
${BROWSER}  chrome
${acct_name}   Deepa Account


*** Test Cases ***
Create Account
    Go To Page              Listing             Account
    Click Object Button                   New
    Wait for modal      New    Account
    Select Record Type              Household Account
   # Wait for modal      New Account: Household Account
    Populate Modal Form     Account Name=${acct_name}
    Click Modal Button              Save

Create Contact
# This Keyword creates org account and contact for that account and verifies in account list.
    ${account}=   API Create Organization Account
    API Create Contact          FirstName=Test          Lastname=Contact        AccountId=${account}[Id]
    Go To Page              Listing             Account
    Verify Record           ${account}[Name]