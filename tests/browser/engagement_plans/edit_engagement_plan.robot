*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Variables ***
${task3_1}  Follow-Up Phone Call3


*** Test Cases ***

Create Engagement Plan and Edit to Add New Task
    [tags]  unstable
    ${plan_name}     ${task1_1}    ${sub_task1_1}     ${task2_1}     Create Engagement Plan
    Unselect Frame
    Select App Launcher Tab  Engagement Plan Templates
    Click Link    link=${plan_name}
    ${ns} =  Get NPSP Namespace Prefix
    ${id}    Get Current Record Id
    Store Session Record    ${ns}Engagement_Plan_Template__c    ${id}
    Click Link    link=Show more actions
    Click Link    link=Edit
    #Sleep    2
    Select Frame With Title    Manage Engagement Plan Template
    Page Scroll To Locator    button    Add Task
    Click Button With Value    Add Task
    Enter Task Id and Subject    Task 3    ${task3_1}
    Page Scroll To Locator    button    Save
    Click Button With Value    Save
    Unselect Frame
    Verify Engagement Plan    ${plan_name}    ${task1_1}    ${sub_task1_1}     ${task2_1}    ${task3_1}
    
