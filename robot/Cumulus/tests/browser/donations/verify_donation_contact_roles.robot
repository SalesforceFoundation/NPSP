*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Create Donation from Contact and Verify Contact Roles on Opportunity Page
    ${ns} =  Get NPSP Namespace Prefix
    &{contact1} =  API Create Contact    Email=skristem@robot.com
    Store Session Record    Account    &{contact1}[AccountId]
    &{contact2} =  API Create Contact    AccountId=&{contact1}[AccountId]
    &{opportunity} =  API Create Opportunity    &{Contact1}[AccountId]    Donation    Name=Role test $100 donation
    Go To Record Home  &{opportunity}[Id]
    Select Tab  Related
    Wait For Locator    record.related.check_occurrence    Contact Roles    2
    Select Relatedlist    Contact Roles
    Verify Related List Field Values
    ...                     &{contact1}[FirstName] &{contact1}[LastName]=Donor
    ...                     &{contact2}[FirstName] &{contact2}[LastName]=Household Member  
    &{opportunity2} =  API Create Opportunity    &{Contact2}[AccountId]    Donation    
    ...            Name=Rollup test $50 donation    
    ...            ${ns}Primary_Contact__c=&{contact2}[Id]
    ...            Amount=50
    Go To Record Home  &{contact1}[AccountId]
    Select Tab    Details
    Scroll Element Into View    text:Membership Information
    Confirm Field Value           Total Gifts    contains    $150.00    
    Confirm Field Value           Total Number of Gifts    contains    2    
    Run Donations Batch Process
    Go To Record Home  &{contact1}[Id]
    Scroll Element Into View    text:Soft Credit Total
    Confirm Field Value           Total Gifts    contains    $100.00    
    Confirm Field Value           Total Number of Gifts    contains    1    
    Scroll Element Into View    text:Household Donation Info
    Confirm Field Value           Soft Credit Total    contains    $50.00    
    Confirm Field Value           Number of Soft Credits    contains    1    
