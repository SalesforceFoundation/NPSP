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
    Setupdata   engagement  engagement_data=${engagement_fields}


*** Variables ***
${task1}  Task_1
${task2}  Task_2
&{engagement_fields}  Name=AutomationTestPlan


*** Test Cases ***
Create Engagement Plan And Edit the Plan
    [Documentation]                      Create an engagement plan , Edit the Engagement plan and add tasks
    ...                                  Verify the engagement plan added appears in the list with the edited
    ...                                  tasks.
    [tags]                               feature:Engagements     unstable    api


    Go To Page                                        Listing                             Engagement_Plan_Template__c
    Go To Engagement Plan Page                        Edit                                ${data}[engagement][Id]
    Current Page Should Be                            Home                                Engagement_Plan_Template__c

    Click Task Button                                 Task 1
    Enter Task Id and Subject                         Task 1                             Task_1
    Click Task Button                                 Task 2
    Enter Task Id and Subject                         Task 2                             Task_2
    Save Engagement Plan Template

    Go To Page                                        Detail
    ...                                               EngagementTemplate
    ...                                               object_id=${data}[engagement][Id]
    Check Field Value                                 Engagement Plan Template Name         AutomationTestPlan
    Select Tab                                        Related
    Check Related List Values                         Engagement Plan Tasks                 ${task1}  ${task2}
