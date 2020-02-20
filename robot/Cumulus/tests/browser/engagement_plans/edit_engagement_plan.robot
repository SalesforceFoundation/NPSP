*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/EngagementPlanTemplatesPageObject.py
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Variables ***
${task3_1}  Follow-Up Phone Call3


*** Test Cases ***

Create Engagement Plan and Edit to Add New Task
    [tags]  unstable
    ${plan_name}     ${task1_1}    ${sub_task1_1}     ${task2_1}     Create Engagement Plan
    Unselect Frame
    Go To Page                        Listing                 Engagement_Plan_Template__c
    Click Link    link=${plan_name}
    Current Page Should Be    Details   Engagement_Plan_Template__c
    Click Show More Actions Button    Edit
    Click New Task Button   Manage Engagement Plan Template    button    Add Task
    Enter Task Id and Subject    Task 3    ${task3_1}
    Page Scroll To Locator    button    Save
    Click Button With Value    Save
    Wait Until Location Contains    /view    
    Unselect Frame
    Verify Engagement Plan    ${plan_name}    ${task1_1}    ${sub_task1_1}     ${task2_1}    ${task3_1}
    
*** Keywords ***
Click New Task Button
    [Arguments]       ${frame_name}    ${ele_path}     @{others}
    Wait Until Location Contains    /edit
    Select Frame And Click Element    ${frame_name}    ${ele_path}     @{others}