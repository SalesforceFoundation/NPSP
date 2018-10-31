*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Create a Contact and Add Engagement Plan
    [tags]  unstable
    ${plan_name}     ${task1_1}    ${sub_task1_1}     ${task2_1}     Create Engagement Plan
    ${contact_id} =  Create Contact with Address
    &{contact} =  Salesforce Get  Contact  ${contact_id}
    Header Field Value    Account Name    &{contact}[LastName] Household
    #Scroll Page To Location    0    500
    Click Related List Button  Engagement Plans    New
    Populate Lookup Field    Engagement Plan Template    ${plan_name}
    Click Modal Button        Save
    Verify Occurance    Engagement Plans    1
    ${plan_num}    Verify Eng Plan Exists    Engagement Plans       
    Log To Console    ${plan_num}
    
Delete Engagement Plan
    [tags]  unstable
    Sleep    2
    ${plan_num}    Verify Eng Plan Exists    Engagement Plans    True
    Sleep    2
    Click Link    link=Delete
    Click Modal Button        Delete
    Verify Occurance    Engagement Plans    0    
    
Verify Tasks Exist Under Activity
    [tags]  unstable
    Sleep    2
    Scroll Page To Location    0    0
    Click Span Button    More Steps
    Check Activity Tasks    ${task1}    ${sub_task}    ${task2}    