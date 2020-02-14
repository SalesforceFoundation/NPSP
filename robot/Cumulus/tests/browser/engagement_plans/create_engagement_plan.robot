*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/ContactPageObject.py
...             robot/Cumulus/resources/AccountPageObject.py
...             robot/Cumulus/resources/EngagementPlanTemplatesPageObject.py
...             robot/Cumulus/resources/NPSP.py
Suite Setup     Run keywords
...             Open Test Browser
Suite Teardown  Delete Records and Close Browser


*** Variables ***
${task1}  Task_1
${task2}  Task_2
${sub_task1}  subtask1

&{engagement_fields}  Name=AutomationTestPlan
&{fields}  Name=testplan1    task1=Task_1    task2=Task_2

*** Test Cases ***
Create Engagement Plan Template And verify save
    [Documentation]                      Create an engagement plan from the ui. Navigate to engagementplans listings view
    ...                                  View the details of the engagement plan created.

    [tags]                                          W-038641                 feature:Engagements

    Go To Page                                      Listing                             Engagement_Plan_Template__c
    Go To Engagement Plan Page                      create
    Wait For Locator                                frame                               Manage Engagement Plan Template
    Populate Values And Save Template               Create                              ${fields}
    ${ns} =  Get NPSP Namespace Prefix
    Save Current Record ID For Deletion             ${ns}Engagement_Plan_Template__c
    Go To Page                                      Listing                             Engagement_Plan_Template__c
    Click Link                                      link=testplan1
    Check Field Value                               Engagement Plan Template Name       testplan1
    Select Tab                                      Related
    Check Related List Values                       Engagement Plan Tasks               ${task1}  ${task2}
