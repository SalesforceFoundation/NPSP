*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

 
*** Test Cases ***    
ASC Reciprocal Relationship Test Case 1
    [tags]  unstable
    &{contact1} =  API Create Contact    Email=skristem@robot.com 
    &{contact2} =  API Create Contact    AccountId=&{contact1}[AccountId]
    ${ns} =  Get NPSP Namespace Prefix
    &{relation} =  API Create Relationship    &{contact1}[Id]    &{contact2}[Id]    Coworker    ${ns}Related_Opportunity_Contact_Role__c=Soft Credit
    &{opportunity} =  API Create Opportunity    &{contact2}[AccountId]    Donation    Name=Reciprocal test $500 donation    Amount=500    ${ns}Primary_Contact__c=&{contact2}[Id]  
    Go To Record Home    &{opportunity}[Id]
    Select Tab  Related
    Select Relatedlist    Contact Roles
    Verify Related List Field Values
    ...                     &{contact2}[FirstName] &{contact2}[LastName]=Donor
    ...                     &{contact1}[FirstName] &{contact1}[LastName]=Household Member
    Run Donations Batch Process
    Go To Record Home    &{Contact1}[Id]
    ${locator}    Get NPSP Locator    detail_page.section_header    Soft Credit Total
    Scroll Element Into View    ${locator}
    Confirm Value    Soft Credit This Year    $500.00    Y
    Confirm Value    Soft Credit Total    $500.00    Y
    Go To Record Home    &{Contact2}[Id]
    ${locator}    Get NPSP Locator    detail_page.section_header    Soft Credit Total
    Scroll Element Into View    ${locator}
    Confirm Value    Total Gifts This Year    $500.00    Y
    Confirm Value    Total Gifts    $500.00    Y
    Confirm Value    Soft Credit This Year    $0.00    Y
    Confirm Value    Soft Credit Total    $0.00    Y
    
Test Case 2
    [tags]  unstable
    &{contact1} =  API Create Contact    Email=skristem@robot.com 
    &{contact2} =  API Create Contact    AccountId=&{contact1}[AccountId]
    ${ns} =  Get NPSP Namespace Prefix
    &{relation} =  API Create Relationship    &{contact1}[Id]    &{contact2}[Id]    Coworker    ${ns}Related_Opportunity_Contact_Role__c=Soft Credit
    Go To Record Home    &{contact2}[Id]
    Select Tab  Related
    Click Related Item Link    Relationships    &{contact1}[FirstName] &{contact1}[LastName]
    Click Button    title=Edit Related Opportunity Contact Role
    Wait For Locator  record.edit_form
    Click Dropdown            Related Opportunity Contact Role
    Click link    title:Soft Credit
    Click Record Button    Save
    &{opportunity} =  API Create Opportunity    &{contact1}[AccountId]    Donation    Name=Reciprocal test $500 donation    Amount=500    ${ns}Primary_Contact__c=&{contact1}[Id]  
    Go To Record Home    &{opportunity}[Id]
    Select Tab  Related
    Select Relatedlist    Contact Roles
    Verify Related List Field Values
    ...                     &{contact1}[FirstName] &{contact1}[LastName]=Donor
    ...                     &{contact2}[FirstName] &{contact2}[LastName]=Soft Credit
    Run Donations Batch Process
    Go To Record Home    &{Contact2}[Id]
    ${locator}    Get NPSP Locator    detail_page.section_header    Soft Credit Total
    Scroll Element Into View    ${locator}
    Confirm Value    Soft Credit This Year    $500.00    Y
    Confirm Value    Soft Credit Total    $500.00    Y
    Go To Record Home    &{Contact1}[Id]
    ${locator}    Get NPSP Locator    detail_page.section_header    Soft Credit Total
    Scroll Element Into View    ${locator}
    Confirm Value    Total Gifts This Year    $500.00    Y
    Confirm Value    Total Gifts    $500.00    Y
    Confirm Value    Soft Credit This Year    $0.00    Y
    Confirm Value    Soft Credit Total    $0.00    Y
