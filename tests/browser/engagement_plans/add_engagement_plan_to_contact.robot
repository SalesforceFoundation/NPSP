*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Create a Contact and Add Engagement Plan
    ${plan_name}     ${task1_1}    ${sub_task1_1}     ${task2_1}     Create Engagement Plan
    &{contact} =  API Create Contact    MailingStreet=50 Fremont Street    MailingCity=San Francisco    MailingPostalCode=95320    MailingState=CA    MailingCountry=USA
    Go To Record Home  &{contact}[Id]
    Select Tab  Related
    Click Related List Button  Engagement Plans    New
    Populate Lookup Field    Engagement Plan Template    ${plan_name}
    Click Modal Button        Save
    Verify Occurrence    Engagement Plans    1
    
Delete Engagement Plan
    [tags]  unstable
    #Sleep    2
    ${plan_num}    Verify Eng Plan Exists    Engagement Plans    True
    Click Link    link=Delete
    Click Modal Button        Delete
    Verify Occurrence    Engagement Plans    0    
    
Verify Tasks Exist Under Activity
    [tags]  unstable
    #Sleep    2
    Scroll Page To Location    0    0
    Click Span Button    More Steps
    Check Activity Tasks    ${task1}    ${sub_task}    ${task2}    