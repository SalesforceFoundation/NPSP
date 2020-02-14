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
#Suite Teardown  Delete Records and Close Browser

***Keywords***
# Setup a contact with parameters specified
Setup Test Data
    Setupdata   contact   contact_data=${contact_fields}

*** Variables ***
&{contact_fields}  Email=test@example.com
&{fields}  Name=Automation_Plan    task1=Task_1    task2=Task_2

*** Test Cases ***
Create a Contact and Add Engagement Plan
    [Documentation]                      Create data for Engagement plan Template and contact
    ...                                  Create an engagement plan for the contact and verify
    ...                                  There is one engagement plan set up for the contact
    [tags]                               W-038641                 feature:Engagements


    Go To Page                                       Listing                        Engagement_Plan_Template__c
    go to engagement plan page                       create
    Wait For Locator                                 frame                          Manage Engagement Plan Template

    Populate Values And Save Template                Create                         ${fields}
    ${ns} =  Get NPSP Namespace Prefix

    Save Current Record ID For Deletion              ${ns}Engagement_Plan_Template__c
    Go To Page                                       Details
    ...                                              Contact
    ...                                              object_id=${data}[contact][Id]

    Select Tab                                       Related
    Click Related List Button                        Engagement Plans               New
    Populate Lookup Field                            Engagement Plan Template       Automation_Plan
    Click Modal Button                               Save
    Wait Until Modal Is Closed
    Current Page Should Be                           Detail                         Contact
    Validate Related Record Count                    Engagement Plans               1

Delete Engagement Plan
    [Documentation]                      Delete engagement plan from customer
    ...                                  Verify tasks persis
t
    [tags]  unstable
    go to related engagement actionplans page       ${data}[contact][Id]
    Perform Action On Related Item                   Delete
    Go To Page                                       Details
    ...                                              Contact
    ...                                              object_id=${data}[contact][Id]
    Scroll Page To Location                          0                      0
    Check Activity Tasks                             Task_1                Task_2



