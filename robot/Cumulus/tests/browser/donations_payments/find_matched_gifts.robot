*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/ContactPageObject.py
...             robot/Cumulus/resources/AccountPageObject.py
...             robot/Cumulus/resources/OpportunityPageObject.py
...             robot/Cumulus/resources/NPSPSettingsPageObject.py
...             robot/Cumulus/resources/NPSP.py
Suite Setup     Run keywords
...             Open Test Browser
...             Setup Test Data
Suite Teardown  Capture Screenshot and Delete Records and Close Browser

***Keywords***

# Set up all the required data for the test based on the keyword requests
Setup Test Data
    ${ns} =  Get NPSP Namespace Prefix
    &{account_fields} =	Create Dictionary  Type=Organization   ${ns}Matching_Gift_Company__c=true   ${ns}Matching_Gift_Percent__c=100
    setupdata   org     account_data=${account_fields}
    &{opportunity3_fields} =  Create Dictionary  Type=MatchingGift   Name=Rollup test $75 donation   Amount=75   AccountId=${data}[org][Id]
    setupdata   org     opportunity_data=${opportunity3_fields}

    # Create opportunities for contact1 and contact2
    Setupdata   contact1   ${contact1_fields}     opportunity_data=${opportunity1_fields}
    Setupdata   contact2   ${contact2_fields}     opportunity_data=${opportunity2_fields}


*** Variables ***
&{contact1_fields}        Email=contact1@example.com
&{opportunity1_fields}    Type=Donation   Name=Contact1 $50 donation    Amount=50
&{contact2_fields}        Email=contact2@example.com
&{opportunity2_fields}    Type=Donation   Name=Contact2 $25 Donation    Amount=25

*** Test Cases ***

Find Matching Gifts

    Go To Page                             Details
    ...                                    Opportunity
    ...                                    object_id=${data}[contact1_opportunity][Id]
    Current Page Should Be                 Details                           Opportunity
    Click Button                           title:Edit
    Populate Lookup Field                  Matching Gift Account             ${data}[org][Name]
    Select Value From Dropdown             Matching Gift Status              Potential
    Click Modal Button                     Save
    Wait Until Modal Is Closed
    Go To Page                             Details
    ...                                    Opportunity
    ...                                    object_id=${data}[org_opportunity][Id]
    Current Page Should Be                 Details                           Opportunity
    Navigate to Matching Gifts Page

    Page Should Contain Link               Contact1 $50 donation               limit=1
    Set Checkbutton To                     Contact1 $50 donation               checked
    Click Link                             link=Find More Gifts
    Populate Modal Field                   Primary Contact                     ${data}[contact2][FirstName] ${data}[contact2][LastName]
    Click Button With Value                Search
    Set Checkbutton To                     Contact2 $25 Donation                checked
    Click Button With Value                Save
    Current Page Should Be                 Details    Opportunity
    Select Tab                             Related
    Verify Related Object Field Values     Contact Roles
    ...                                    ${data}[contact1][FirstName] ${data}[contact1][LastName]=Matched Donor
    ...                                    ${data}[contact2][FirstName] ${data}[contact2][LastName]=Matched Donor
    Go To Page                             Details
    ...                                    Opportunity
    ...                                    object_id=${data}[org_opportunity][Id]
    Select Tab                             Related
    Verify Related Object Field Values     Partial Soft Credits
    ...                                    ${data}[contact1][FirstName] ${data}[contact1][LastName]=$50.00
    ...                                    ${data}[contact2][FirstName] ${data}[contact2][LastName]=$25.00

    Go To Page                             Details
    ...                                    Opportunity
    ...                                    object_id=${data}[org_opportunity][Id]

    Select Tab    Related
    Verify Related Object Field Values     Matched Gifts
    ...                                    ${data}[contact1_opportunity][Name]=$50.00
    ...                                    ${data}[contact2_opportunity][Name]=$25.00

    Go To Page                             Details
    ...                                    Opportunity
    ...                                    object_id=${data}[contact1_opportunity][Id]
    Navigate To And Validate Field Value   Matching Gift    contains    ${data}[org_opportunity][Name]

    Go To Page                             Details
    ...                                    Opportunity
    ...                                    object_id=${data}[contact2_opportunity][Id]
    Navigate To And Validate Field Value   Matching Gift    contains    ${data}[org_opportunity][Name]

    Run Donations Batch Process

    Go To Page                             Details
    ...                                    Contact
    ...                                    object_id=${data}[contact1][Id]

    Navigate To And Validate Field Value   Total Gifts    contains    $50.00
    Navigate To And Validate Field Value   Soft Credit Total    contains    $50.00

    Go To Page                             Details
    ...                                    Contact
    ...                                    object_id=${data}[contact2][Id]

    Navigate To And Validate Field Value   Total Gifts    contains    $25.00
    Navigate To And Validate Field Value   Soft Credit Total    contains    $25.00

