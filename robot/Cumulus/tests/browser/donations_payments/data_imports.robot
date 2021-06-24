*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/DataImportPageObject.py
Suite Setup     Open Test Browser
#Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Data Imports
    [tags]                     unstable
    ${first_name1} =           Generate Random String
    ${last_name1} =            Generate Random String
    ${acc1}=                   Generate Random String
    ${first_name2} =           Generate Random String
    ${last_name2} =            Generate Random String
    ${acc2}=                   Generate Random String
    Go To Page                Listing                 DataImport__c
    Click Span Button         New
    Wait Until Modal Is Open
    Populate Form
    ...                       Contact1 First Name=${first_name1}
    ...                       Contact1 Last Name=${last_name1}
    ...                       Account1 Name=${acc1}
    ...                       Contact2 First Name=${first_name2}
    ...                       Contact2 Last Name=${last_name2}
    ...                       Account2 Name=${acc2}
    Click Span Button         Save
    Wait Until Modal Is Closed
    Process Data Import Batch    Completed

