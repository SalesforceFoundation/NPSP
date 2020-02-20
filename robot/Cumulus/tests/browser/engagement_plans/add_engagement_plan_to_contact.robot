*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/EngagementPlanTemplatesPageObject.py
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Create a Contact and Add Engagement Plan
    [tags]  unstable
    ${plan_name}     ${task1_1}    ${sub_task1_1}     ${task2_1}     Create Engagement Plan
    Set Suite Variable    ${plan_name}
    &{contact} =  API Create Contact    MailingStreet=50 Fremont Street    MailingCity=San Francisco    MailingPostalCode=95320    MailingState=CA    MailingCountry=USA
    Store Session Record    Account    &{contact}[AccountId]
    Go To Record Home  &{contact}[Id]
    Select Tab  Related
    Click Related List Button  Engagement Plans    New
    Populate Lookup Field    Engagement Plan Template    ${plan_name}
    Click Modal Button        Save
    Validate Related Record Count    Engagement Plans   1

Delete Engagement Plan
    [tags]  unstable
    ${plan_num}    Verify Eng Plan Exists    ${plan_name}
    Click Related Item Popup Link    Engagement Plans    ${plan_num}    Delete
    Click Modal Button        Delete
    Verify Occurence          Engagement Plans       0
    
Verify Tasks Exist Under Activity
    [tags]  unstable
    Scroll Page To Location    0    0
    Click More Activity Button    
    Check Activity Tasks    ${task1}    ${sub_task}    ${task2}
