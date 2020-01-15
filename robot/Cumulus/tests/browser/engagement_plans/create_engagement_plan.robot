*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/EngagementPlanTemplatesPageObject.py
Suite Setup     Open Test Browser
Suite Teardown  Capture Screenshot and Delete Records and Close Browser

*** Test Cases ***

Create Engagement Plan and Verify
    ${plan_name}     ${task1_1}    ${sub_task1_1}     ${task2_1}     Create Engagement Plan
    Unselect Frame
    Verify Engagement Plan    ${plan_name}    ${task1_1}    ${sub_task1_1}     ${task2_1}
