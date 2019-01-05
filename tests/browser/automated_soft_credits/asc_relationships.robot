*** Settings ***

Resource        tests/NPSP.robot
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
    Click Related List Button  Relationships    New
    Populate Lookup Field    Related Contact    &{contact2}[FirstName] &{contact2}[LastName]
    Click Dropdown            Type
    Click link    title:Employer
    Click Dropdown            Related Opportunity Contact Role
    Click link    title:Soft Credit
    Click Modal Button        Save
    Click Related List Button  Relationships    New
    Populate Lookup Field    Related Contact    &{contact3}[FirstName] &{contact3}[LastName]
    Click Dropdown            Type
    Click link    title:Coworker
    Click Dropdown            Related Opportunity Contact Role
    Click link    title:Solicitor
    Click Modal Button        Save
    #&{relation} =  API Create Relationship    &{contact1}[Id]    &{contact3}[Id]    Coworker    ${ns}Related_Opportunity_Contact_Role__c=Solicitor
    &{opportunity} =  API Create Opportunity    &{Contact1}[AccountId]    Donation    Name=&{Contact1}[FirstName] $100 donation    Amount=100
    Go To Record Home    &{opportunity}[Id]
    Select Relatedlist    Contact Roles
    Verify Related List Field Values
    ...                     &{contact1}[FirstName] &{contact1}[LastName]=Donor
    ...                     &{contact2}[FirstName] &{contact2}[LastName]=Soft Credit
    ...                     &{contact3}[FirstName] &{contact3}[LastName]=Solicitor
    Go To Record Home    &{contact2}[Id]
    Load Related List    Opportunities
    Check Record Related Item    Opportunities    &{opportunity}[Name]
    Go To Record Home    &{contact3}[Id]
    Load Related List    Opportunities
    Check Record Related Item    Opportunities    &{opportunity}[Name]
    Run Donations Batch Process
    Go To Record Home    &{Contact2}[Id]
    ${locator}    Get NPSP Locator    detail_page.section_header    Soft Credit Totals
    Select Tab    Details
    Scroll Element Into View    ${locator}
    Confirm Value    Soft Credit This Year    $100.00    Y
    Confirm Value    Soft Credit Total    $100.00    Y
    Go To Record Home    &{Contact3}[Id]
    ${locator}    Get NPSP Locator    detail_page.section_header    Soft Credit Totals
    Select Tab    Details
    Scroll Element Into View    ${locator}
    Confirm Value    Soft Credit This Year    $0.00    Y
    Confirm Value    Soft Credit Total    $0.00    Y
