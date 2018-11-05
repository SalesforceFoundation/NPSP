*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Create Engagement Plan and Verify
    [tags]  unstable
    ${plan_name}     ${task1_1}    ${sub_task1_1}     ${task2_1}     Create Engagement Plan
    Verify Engagement Plan    ${plan_name}    ${task1_1}    ${sub_task1_1}     ${task2_1}
    