*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/GAUPageObject.py
Suite Setup     Open Test Browser
Suite Teardown  Capture Screenshot and Delete Records and Close Browser

*** Test Cases ***

Create GAU and Verify
     [Documentation]                   Create a General Accounting Unit name from  the UI
     [tags]                            feature:GAU     unit

     ${gau_name} =                     Generate Random String
     Go To Page                        Listing
     ...                               General_Accounting_Unit__c
     Click Object Button               New
     Wait Until Modal Is Open
     Populate Form
     ...                               General Accounting Unit Name=${gau_name}
     ...                               Largest Allocation=5
     Click Button                      title=Save
     Wait Until Modal Is Closed
     ${gau_name}                       Get Main Header
     Go To Page                        Listing
     ...                               General_Accounting_Unit__c
     Click Link                        link=${gau_name}