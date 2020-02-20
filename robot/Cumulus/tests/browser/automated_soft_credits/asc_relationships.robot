*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/NPSPSettingsPageObject.py
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Create ASC for Related Contact
    [tags]  unstable
    &{contact1} =  API Create Contact    Email=skristem@robot.com
    &{contact2} =  API Create Contact    Email=skristem@robot.com
    &{contact3} =  API Create Contact    AccountId=&{contact1}[AccountId]
    #${ns} =  Get NPSP Namespace Prefix
    Go To Record Home    &{contact1}[Id]
    Select Tab    Related
    Click Related List Button  Relationships    New
    Wait Until Modal Is Open
    Populate Lookup Field    Related Contact    &{contact2}[FirstName] &{contact2}[LastName]
    Select Value From Dropdown   Type              Employer
    Select Value From Dropdown   Related Opportunity Contact Role              Soft Credit
    Click Modal Button        Save
    Wait Until Modal Is Closed
    Click Related List Button  Relationships    New
    Wait Until Modal Is Open
    Populate Lookup Field    Related Contact    &{contact3}[FirstName] &{contact3}[LastName]
    Select Value From Dropdown   Type              Coworker
    Select Value From Dropdown   Related Opportunity Contact Role              Solicitor
    Click Modal Button        Save
    Wait Until Modal Is Closed
    #&{relation} =  API Create Relationship    &{contact1}[Id]    &{contact3}[Id]    Coworker    ${ns}Related_Opportunity_Contact_Role__c=Solicitor
    &{opportunity} =  API Create Opportunity    &{Contact1}[AccountId]    Donation    Name=&{Contact1}[FirstName] $100 donation    Amount=100
    Go To Record Home    &{opportunity}[Id]
    Select Tab    Related
    Select Relatedlist    Contact Roles
    Verify Related List Field Values
    ...                     &{contact1}[FirstName] &{contact1}[LastName]=Donor
    ...                     &{contact2}[FirstName] &{contact2}[LastName]=Soft Credit
    ...                     &{contact3}[FirstName] &{contact3}[LastName]=Solicitor
    Go To Record Home    &{contact2}[Id]
    Select Tab    Related
    Load Related List    Opportunities
    Check Record Related Item    Opportunities    &{opportunity}[Name]
    Go To Record Home    &{contact3}[Id]
    Select Tab    Related
    Load Related List    Opportunities
    Check Record Related Item    Opportunities    &{opportunity}[Name]
    Run Donations Batch Process
    Go To Record Home    &{Contact2}[Id]
    ${locator}    Get NPSP Locator    detail_page.section_header    Soft Credit Total
    Scroll Element Into View    ${locator}
    Navigate To And Validate Field Value    Soft Credit This Year    contains    $100.00
    Navigate To And Validate Field Value    Soft Credit Total    contains    $100.00
    Go To Record Home    &{Contact3}[Id]
    ${locator}    Get NPSP Locator    detail_page.section_header    Soft Credit Total
    Scroll Element Into View    ${locator}
    Navigate To And Validate Field Value    Soft Credit This Year    contains    $0.00
    Navigate To And Validate Field Value    Soft Credit Total    contains    $0.00
