*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/ContactPageObject.py
...             robot/Cumulus/resources/OpportunityPageObject.py
...             robot/Cumulus/resources/OpportunityContactRolePageObject.py
...             robot/Cumulus/resources/NPSPSettingsPageObject.py
Suite Setup     Run keywords
...             Open Test Browser
...             Setup Test Data
Suite Teardown  Capture Screenshot and Delete Records and Close Browser

***Keywords***
Setup Test Data
    Setupdata           account      None    None    ${account_fields}
    Setupdata           contact     ${contact_fields}

*** Variables ***

&{contact_fields}  Email=test@example.com
&{account_fields}  Type=Organization

*** Test Cases ***
Create ASC for Affiliated Contact
    [Documentation]            Create a contact and Org Account via API.Open contact and create an affiliation to the org with
    ...                        Opp contact role as Soft Credit. Create an opportunity amount as 500, stage as closed won, close date as today.
    ...                        Verify contact shows under contact role with Role as soft credit.
    ...                        After running donations batch job verify contact gets soft credits
    [tags]                     feature:Automated Soft Credits        W-039819

    #Create Affiliation
    Go To Page                              Details                              Contact
    ...                                     object_id=${data}[contact][Id]
    Select Tab                              Related
    Click Related List Button               Organization Affiliations            New
    Wait For Modal                          New                                  Affiliation
    Populate Lookup Field                   Organization                         ${data}[account][Name]
    Click Flexipage Dropdown                Related Opportunity Contact Role     Soft Credit
    Click Button                            Save
    Wait Until Modal Is Closed

    #Create opportunity and verify contact role
    &{opportunity} =                        API Create Opportunity               ${data}[account][Id]    Donation
    ...                                     Name=${data}[account][Name] $500 donation
    ...                                     Amount=500

    Go To Page                              Details                              Opportunity
    ...                                     object_id=${opportunity}[Id]
    Select Tab                              Related
    Select Relatedlist                      Contact Roles
    Wait For Page Object                    Custom                               OpportunityContactRole
    Verify Related List Field Values
    ...                                     ${data}[contact][FirstName] ${data}[contact][LastName]=Soft Credit

    Go To Page                              Details                              Contact
    ...                                     object_id=${data}[contact][Id]
    Select Tab                              Related
    Check Record Related Item               Opportunities                        ${opportunity}[Name]

    #Run batch job and verify soft credits on contact
    Run Donations Batch Process
    Go To Page                              Details                              Contact
    ...                                     object_id=${data}[contact][Id]
    Navigate To And Validate Field Value    Soft Credit This Year    contains    $500.00    section=Soft Credit Total
    Navigate To And Validate Field Value    Soft Credit Total        contains    $500.00    section=Soft Credit Total
