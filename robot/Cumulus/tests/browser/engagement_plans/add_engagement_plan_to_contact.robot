*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/ContactPageObject.py
...             robot/Cumulus/resources/AccountPageObject.py
...             robot/Cumulus/resources/EngagementPlanTemplatesPageObject.py
...             robot/Cumulus/resources/NPSP.py

Suite Setup     Run keywords
...             Open Test Browser
...             Setup Test Data
Suite Teardown  Capture Screenshot and Delete Records and Close Browser

***Keywords***
# Setup a contact with parameters specified
Setup Test Data
    Setupdata   contact   contact_data=${contact_fields}

*** Variables ***
&{contact_fields}  Email=test@example.com

*** Test Cases ***
Create a Contact and Add Engagement Plan
    [Documentation]                      Create an Engagement plan Template with two tasks and one subtask. And  a contact
    ...                                  Link the  engagement plan for the contact and verify
    ...                                  There is one engagement plan set up for the contact
    [tags]                               W-038641                 feature:Engagements


    Go To Page                                       Listing                            Engagement_Plan_Template__c
    Go To Engagement Plan Page                       create
    Current Page Should Be                           Home                               Engagement_Plan_Template__c
    Enter Eng Plan Values                            idName                             Automation_Plan
    Enter Eng Plan Values                            idDesc                             This plan is created via Automation
    Click Task Button                                Task 1
    Enter Task Id and Subject                        Task 1                             Task_1
    Click Task Button                                Add Dependent Task                 1                               subtask
    Enter Task Id and Subject                        Task 1-1                           Sub_task_1.1
    Click Task Button                                Task 2
    Enter Task Id and Subject                        Task 2                             Task_2
    Save Engagement Plan Template

    Current Page Should Be                           Details                            Engagement_Plan_Template__c
    ${ns} =  Get NPSP Namespace Prefix

    Save Current Record ID For Deletion              ${ns}Engagement_Plan_Template__c
    Go To Page                                       Details
    ...                                              Contact
    ...                                              object_id=${data}[contact][Id]

    Select Tab                                       Related
    Click Related List Button                        Engagement Plans               New
    Wait Until Modal Is Open
    Populate Lookup Field                            Engagement Plan Template       Automation_Plan
    Click Button                                     Save
    Wait Until Modal Is Closed
    Current Page Should Be                           Detail                         Contact
    Validate Related Record Count                    Engagement Plans               1
    Go To Related Engagement Actionplans Page        ${data}[contact][Id]
    Perform Action On Related Item                   Delete
    Go To Page                                       Details
    ...                                              Contact
    ...                                              object_id=${data}[contact][Id]
    Click More Activity Button
    Check Activity Tasks                            Task_1    Sub_task_1.1    Task_2



