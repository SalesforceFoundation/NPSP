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

     Go To Page                                       Listing                            Engagement_Plan_Template__c
     go to engagement plan page                       create
     Wait For Locator                                 frame                              Manage Engagement Plan Template

     Select Frame And Click Element                   Manage Engagement Plan Template    id    idName
     Enter Eng Plan Values                            idName                             Auto_Eng_Plan
     Enter Eng Plan Values                            idDesc                             This plan is created via Automation
     Click Button                                     Add Task
     Wait Until Page Contains                         Task 1
     Enter Task Id and Subject                        Task 1                             Task_1
     Click Button                                     Add Task
     Wait Until Page Contains                         Task 2
     Enter Task Id and Subject                        Task 2                             Task_2
     Page Scroll To Locator                           button                             Save
     Click Button                                     Save
     wait until location contains                     /view
     ${ns} =  Get NPSP Namespace Prefix
     Save Current Record ID For Deletion             ${ns}Engagement_Plan_Template__c
     Go To Page                                      Listing                             Engagement_Plan_Template__c
     Click Link                                      link=Auto_Eng_Plan
     Check Field Value                               Engagement Plan Template Name       Auto_Eng_Plan
     Select Tab                                      Related
     Check Related List Values                       Engagement Plan Tasks               Task_1  Task_2
