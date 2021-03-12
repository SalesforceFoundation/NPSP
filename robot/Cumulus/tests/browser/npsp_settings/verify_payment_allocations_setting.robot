*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/CustomSettingsPageObject.py
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Verify Payment Allocations is Disabled by Default
    [Documentation]                 Go to Custom Settings and Manage Allocations Settings and 
    ...                             verify that Payment Allcocations Enabled checkbox is unchecked by default
    [tags]                          feature:NPSP Settings                   W-039822             unstable            notonfeaturebranch
    Go To Page                      Custom                                  CustomSettings
    Select Settings Option          Allocations Settings                    Manage
    Verify Page And Select Frame    Allocations Settings
    Wait Until Element Is Visible   text:Default Organization Level Value
    Checkbox Status                 Payment Allocations Enabled             Not Checked
    