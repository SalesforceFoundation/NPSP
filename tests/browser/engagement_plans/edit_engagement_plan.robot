*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Variables ***
${task3_1}  Follow-Up Phone Call


*** Test Cases ***

Create Engagement Plan and Edit to Add New Task
    [tags]  unstable
    ${plan_name}     ${task1_1}    ${sub_task1_1}     ${task2_1}     Create Engagement Plan
    Go To Object Home         npsp__Engagement_Plan_Template__c
    Click Link    link=${plan_name}
    Click Link    link=Edit
    Sleep    2
    Select Frame With Title    Manage Engagement Plan Template
    Scroll Page to Location    0     500
    Click Task Button    Add Task
    Enter Task Id and Subject    86    ${task3_1}
    Scroll Page To Location    50    0
    Click Task Button    Save
    Verify Engagement Plan    ${plan_name}    ${task1_1}    ${sub_task1_1}     ${task2_1}    ${task3_1}
    