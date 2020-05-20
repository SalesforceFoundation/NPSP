*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/GiftEntryPageObject.py
Suite Setup     Open Test Browser
Suite Teardown  Capture Screenshot and Delete Records and Close Browser

*** Variables ***

*** Test Cases ***
Create Gift
    Go To Page      Landing     GE_Gift_Entry
    Click Button With Title     New Single Gift
    Fill Ge Form	Donor Type      Account
    