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
    Setupdata   contact1   ${contact1_fields}
    Setupdata   contact2   ${contact2_fields}
    &{contact3_fields} =	Create Dictionary  Email=test3@example.com  AccountId=${data}[contact1][AccountId]
    Setupdata   contact3   ${contact3_fields}

*** Variables ***

&{contact1_fields}  Email=test1@example.com
&{contact2_fields}  Email=test2@example.com

*** Test Cases ***

Create ASC for Related Contact
    [Documentation]                Create three contacts. From contact1, create a relation with contact2 with type Employer and Related OCR as Soft Credit.
    ...                            Create a relation with contact3 with type as Coworker and Related OCR as solicitor. From Contact1 create an opp
    ...                            verify contact roles. Run donations batch and verify contact2 has soft credits and contact3 does not have soft credits
    [tags]                         feature:Automated Soft Credits       W-039819            unstable             notonfeaturebranch
    Go To Page                              Details                              Contact
    ...                                     object_id=${data}[contact1][Id]
    Select Tab                              Related
    Click Related List Button               Relationships                        New
    Wait For Modal                          New                                  Relationship
    Populate Lookup Field                   Related Contact                      ${data}[contact2][FirstName] ${data}[contact2][LastName]
    Click Flexipage Dropdown                Type                                 Employer
    Click Flexipage Dropdown                Related Opportunity Contact Role     Soft Credit
    Click Button                            Save
    Wait Until Modal Is Closed
    ${ns} =                                 Get NPSP Namespace Prefix
    API Create Relationship                 ${data}[contact1][Id]    ${data}[contact3][Id]    Coworker    ${ns}Related_Opportunity_Contact_Role__c=Solicitor
    &{opportunity} =                        API Create Opportunity               ${data}[contact1][AccountId]    Donation
    ...                                     Name=${data}[contact1][FirstName] $100 donation
    ...                                     Amount=100
    Go To Page                              Details                              Opportunity
    ...                                     object_id=${opportunity}[Id]
    Select Tab                              Related
    Select Relatedlist                      Contact Roles
    Wait For Page Object                    Custom                               OpportunityContactRole
    Verify Related List Field Values
    ...                                     ${data}[contact1][FirstName] ${data}[contact1][LastName]=Donor
    ...                                     ${data}[contact2][FirstName] ${data}[contact2][LastName]=Soft Credit
    ...                                     ${data}[contact3][FirstName] ${data}[contact3][LastName]=Solicitor
    Go To Page                              Details                              Contact
    ...                                     object_id=${data}[contact2][Id]
    Select Tab                              Related
    Check Record Related Item               Opportunities                        ${opportunity}[Name]
    Go To Page                              Details                              Contact
    ...                                     object_id=${data}[contact3][Id]
    Select Tab                              Related
    Check Record Related Item               Opportunities                        ${opportunity}[Name]
    Run Donations Batch Process
    Go To Page                              Details                              Contact
    ...                                     object_id=${data}[contact2][Id]
    Navigate To And Validate Field Value    Soft Credit This Year    contains    $100.00    section=Soft Credit Total
    Navigate To And Validate Field Value    Soft Credit Total        contains    $100.00    section=Soft Credit Total
    Go To Page                              Details                              Contact
    ...                                     object_id=${data}[contact3][Id]
    Navigate To And Validate Field Value    Soft Credit This Year    contains    $0.00    section=Soft Credit Total
    Navigate To And Validate Field Value    Soft Credit Total        contains    $0.00    section=Soft Credit Total
