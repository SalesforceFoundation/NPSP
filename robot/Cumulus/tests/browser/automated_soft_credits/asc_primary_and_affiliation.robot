*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

 
*** Test Cases ***    
Create ASC Test for Primary and Affiliations
    [tags]  unstable
    &{account} =  API Create Organization Account   
    &{contact1} =  API Create Contact    Email=skristem@robot.com 
    &{contact2} =  API Create Contact    Email=skristem@robot.com
    ${ns} =  Get NPSP Namespace Prefix
    &{affiliation1} =  API Create Secondary Affiliation    &{account}[Id]    &{contact1}[Id]    ${ns}Related_Opportunity_Contact_Role__c=Soft Credit
    &{affiliation2} =  API Create Secondary Affiliation    &{account}[Id]    &{contact2}[Id]    ${ns}Related_Opportunity_Contact_Role__c=Solicitor
    &{opportunity} =  API Create Opportunity    &{account}[Id]    Donation    Name=&{account}[Name] $50 donation    Amount=50    ${ns}Primary_Contact__c=&{contact1}[Id]
    Go To Record Home    &{opportunity}[Id]
    Select Tab    Related
    Select Relatedlist    Contact Roles
    Verify Related List Field Values
    ...                     &{contact1}[FirstName] &{contact1}[LastName]=Soft Credit
    ...                     &{contact2}[FirstName] &{contact2}[LastName]=Solicitor
    Go To Record Home    &{contact1}[Id]
    Select Tab    Related
    Load Related List    Opportunities
    Check Record Related Item    Opportunities    &{opportunity}[Name]
    Go To Record Home    &{contact2}[Id]
    Select Tab    Related
    Load Related List    Opportunities
    Check Record Related Item    Opportunities    &{opportunity}[Name]
    Run Donations Batch Process
    Go To Record Home    &{Contact1}[Id]
    ${locator}    Get NPSP Locator    detail_page.section_header    Soft Credit Total
    Scroll Element Into View    ${locator}
    Confirm Value    Soft Credit This Year    $50.00    Y
    Confirm Value    Soft Credit Total    $50.00    Y
    Go To Record Home    &{Contact2}[Id]
    ${locator}    Get NPSP Locator    detail_page.section_header    Soft Credit Total
    Scroll Element Into View    ${locator}
    Confirm Value    Soft Credit This Year    $0.00    Y
    Confirm Value    Soft Credit Total    $0.00    Y
