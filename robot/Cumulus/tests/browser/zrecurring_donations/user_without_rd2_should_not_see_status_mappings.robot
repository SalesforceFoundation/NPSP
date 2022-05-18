*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/NPSPSettingsPageObject.py
Suite Setup     Run keywords
...             Open Test Browser
Suite Teardown  Capture Screenshot and Delete Records and Close Browser


*** Test Cases ***

User On A Non RD2 Enbaled Org should Not See Status Mappings Option
    [Documentation]               On an org without rd2 enabled, a user
     ...                          Should not see the option Status to state mapping option
     ...                          Under NPSP Settings


    [tags]                        W-8211276

    Go To Page                   Custom                        NPSP_Settings
    Open Main Menu               Recurring Donations
    Verify Sub Link Present      Status to State Mapping       False
