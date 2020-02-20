*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/NPSPSettingsPageObject.py
...             robot/Cumulus/resources/OpportunityPageObject.py
Suite Setup     Open Test Browser
Suite Teardown  Capture Screenshot and Delete Records and Close Browser


*** Test Cases ***

Find Matching Gifts
    [tags]  unstable
    ${ns} =  Get NPSP Namespace Prefix
    &{Org} =  API Create Organization Account    ${ns}Matching_Gift_Company__c=true  ${ns}Matching_Gift_Percent__c=100
    &{contact1} =  API Create Contact    Email=automation@example.com
    &{opportunity1} =  API Create Opportunity    &{Contact1}[AccountId]    Donation    Name=&{Contact1}[FirstName] $50 donation    Amount=50
    Go To Record Home  &{opportunity1}[Id]
    Click More Actions Button
    Click Link    link=Edit
    Populate Lookup Field    Matching Gift Account    &{Org}[Name]
    Select Value From Dropdown   Matching Gift Status              Potential
    Click Modal Button        Save
    &{contact2} =  API Create Contact    Email=automation@example.com
    &{opportunity2} =  API Create Opportunity    &{Contact2}[AccountId]    Donation    Name=&{Contact2}[FirstName] $25 donation    Amount=25
    &{opportunity3} =  API Create Opportunity    &{Org}[Id]    MatchingGift    Name=&{Org}[Name] $75 matching gift    Amount=75
    Go To Record Home  &{opportunity3}[Id]
    Click More Actions Button
    Click Link    link=Find Matched Gifts
    Choose Frame    vfFrameId
    Page Should Contain Link    &{Contact1}[FirstName] $50 donation    limit=1
    Set Checkbutton To     &{Contact1}[FirstName] $50 donation    checked
    Click Link    link=Find More Gifts
    Populate Modal Field    Primary Contact    &{Contact2}[FirstName] &{Contact2}[LastName]
    Click Button With Value    Search
    Set Checkbutton To     &{Contact2}[FirstName] $25 donation    checked
    Click Button With Value    Save 
    Current Page Should Be    Details    Opportunity
    Select Tab    Related  
    Verify Related Object Field Values    Contact Roles
    ...                     &{contact1}[FirstName] &{contact1}[LastName]=Matched Donor
    ...                     &{contact2}[FirstName] &{contact2}[LastName]=Matched Donor
    Go To Record Home  &{opportunity3}[Id]
    Select Tab    Related
    Verify Related Object Field Values    Partial Soft Credits
    ...                     &{contact1}[FirstName] &{contact1}[LastName]=$50.00
    ...                     &{contact2}[FirstName] &{contact2}[LastName]=$25.00  
    Go To Record Home  &{opportunity3}[Id]
    Select Tab    Related
    Verify Related Object Field Values    Matched Gifts
    ...                     &{opportunity1}[Name]=$50.00
    ...                     &{opportunity2}[Name]=$25.00  
    Go To Record Home  &{opportunity1}[Id]
    ${locator}    Get NPSP Locator    detail_page.section_header    Matching Gift Information
    Scroll Element Into View    ${locator}
    Navigate To And Validate Field Value    Matching Gift    contains    &{opportunity3}[Name]
    Go To Record Home  &{opportunity2}[Id]
    ${locator}    Get NPSP Locator    detail_page.section_header    Matching Gift Information
    Scroll Element Into View    ${locator}
    Navigate To And Validate Field Value    Matching Gift    contains    &{opportunity3}[Name]
    Run Donations Batch Process
    Go To Record Home    &{Contact1}[Id]
    ${locator}    Get NPSP Locator    detail_page.section_header    Soft Credit Total
    Scroll Element Into View    ${locator}
    Navigate To And Validate Field Value    Total Gifts    contains    $50.00
    Navigate To And Validate Field Value   Soft Credit Total    contains    $50.00
    Go To Record Home    &{Contact2}[Id]
    ${locator}    Get NPSP Locator    detail_page.section_header    Soft Credit Total
    Scroll Element Into View    ${locator}
    Navigate To And Validate Field Value    Total Gifts    contains    $25.00
    Navigate To And Validate Field Value    Soft Credit Total    contains    $25.00
