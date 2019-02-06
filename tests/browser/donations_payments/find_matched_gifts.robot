*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser


*** Test Cases ***

Find Matching Gifts
    [tags]  unstable
    ${ns} =  Get NPSP Namespace Prefix
    &{Org} =  API Create Organization Account    ${ns}Matching_Gift_Company__c=true  ${ns}Matching_Gift_Percent__c=100
    &{contact1} =  API Create Contact    Email=skristem@robot.com
    &{opportunity1} =  API Create Opportunity    &{Contact1}[AccountId]    Donation    Name=&{Contact1}[FirstName] $50 donation    Amount=50
    Go To Record Home  &{opportunity1}[Id]
    Click Link    link=Show more actions
    Click Link    link=Edit
    Populate Lookup Field    Matching Gift Account    &{Org}[Name]
    Click Dropdown    Matching Gift Status
    Click Link    link=Potential
    Click Modal Button        Save
    &{contact2} =  API Create Contact    Email=skristem@robot.com
    &{opportunity2} =  API Create Opportunity    &{Contact2}[AccountId]    Donation    Name=&{Contact2}[FirstName] $25 donation    Amount=25
    &{opportunity3} =  API Create Opportunity    &{Org}[Id]    MatchingGift    Name=&{Org}[Name] $75 matching gift    Amount=75
    Go To Record Home  &{opportunity3}[Id]
    Click Link    link=Show more actions
    Click Link    link=Find Matched Gifts
    Select Frame with Name    vfFrameId
    Page Should Contain Link    &{Contact1}[FirstName] $50 donation    limit=1
    Select Lightning Table Checkbox     &{Contact1}[FirstName] $50 donation
    Click Link    link=Find More Gifts
    Populate Modal Field    Primary Contact    &{Contact2}[FirstName] &{Contact2}[LastName]
    Click Button With Value    Search
    Select Lightning Table Checkbox     &{Contact2}[FirstName] $25 donation
    Click Button With Value    Save 
    Reload Page
    Select Tab    Related  
    Select Relatedlist    Contact Roles
    Verify Related List Field Values
    ...                     &{contact1}[FirstName] &{contact1}[LastName]=Matched Donor
    ...                     &{contact2}[FirstName] &{contact2}[LastName]=Matched Donor
    Go To Record Home  &{opportunity3}[Id]
    Select Tab    Related
    Select Relatedlist    Partial Soft Credits
    Verify Related List Field Values
    ...                     &{contact1}[LastName] Household=$50.00
    ...                     &{contact2}[LastName] Household=$25.00  
    Go To Record Home  &{opportunity3}[Id]
    Select Tab    Related
    Load Related List    Matched Gifts
    Click Viewall Related List    Matched Gifts
    Verify Related List Field Values
    ...                     &{opportunity1}[Name]=$50.00
    ...                     &{opportunity2}[Name]=$25.00  
    Go To Record Home  &{opportunity1}[Id]
    ${locator}    Get NPSP Locator    detail_page.section_header    Matching Gift Information
    Scroll Element Into View    ${locator}
    Verify Field Value    Matching Gift    &{opportunity3}[Name]    Y
    Go To Record Home  &{opportunity2}[Id]
    ${locator}    Get NPSP Locator    detail_page.section_header    Matching Gift Information
    Scroll Element Into View    ${locator}
    Verify Field Value    Matching Gift    &{opportunity3}[Name]    Y
    Run Donations Batch Process
    Go To Record Home    &{Contact1}[Id]
    ${locator}    Get NPSP Locator    detail_page.section_header    Soft Credit Total
    Scroll Element Into View    ${locator}
    Confirm Value    Total Gifts    $50.00    Y
    Confirm Value    Soft Credit Total    $50.00    Y
    Go To Record Home    &{Contact2}[Id]
    ${locator}    Get NPSP Locator    detail_page.section_header    Soft Credit Total
    Scroll Element Into View    ${locator}
    Confirm Value    Total Gifts    $25.00    Y
    Confirm Value    Soft Credit Total    $25.00    Y