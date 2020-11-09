*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/NPSPSettingsPageObject.py
...             robot/Cumulus/resources/ContactPageObject.py
...             robot/Cumulus/resources/RecurringDonationsPageObject.py
...             robot/Cumulus/resources/OpportunityPageObject.py
Suite Setup     Run keywords
...             Enable RD2
...             Open Test Browser
Suite Teardown  Capture Screenshot and Delete Records and Close Browser



*** Test Cases ***

User On A RD2 Enbaled Org should Not See Status Mappings Option
    [Documentation]               On an org with rd2 enabled, a user
     ...                          Should see the option Status to state mapping option
     ...                          When


    [tags]                       unstable                          W-8211315
    Open NPSP Settings           Recurring Donations               Status to State Mapping
    Verify Status To State Mappings
    ...                          Active=Active
    ...                          Lapsed=Lapsed
    ...                          Closed=Closed
    ...                          Paused=Active

