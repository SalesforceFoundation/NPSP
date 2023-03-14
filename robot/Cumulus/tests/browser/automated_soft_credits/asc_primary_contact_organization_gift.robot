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

*** Keywords ***
Setup Test Data
    Setupdata           account     None    None  ${account_fields}
    Setupdata           contact     ${contact_fields}
    ${ns} =             Get NPSP Namespace Prefix
    &{opportunity} =    API Create Opportunity    ${data}[account][Id]    Donation
    ...                 Name=${data}[account][Name] $50 donation          Amount=50    ${ns}Primary_Contact__c=${data}[contact][Id]
    Set suite variable  &{opportunity}

*** Variables ***
&{contact_fields}  Email=test@example.com
&{account_fields}  Type=Organization

*** Test Cases ***
Create ASC for Primary Contact on Organization Gift
    [Documentation]            Create a contact, Org Account and Opportunity for acct with contact as primary via API.
    ...                        Verify contact shows under contact role with Role as soft credit.
    ...                        After running donations batch job verify contact gets soft credits
    [tags]                     feature:Automated Soft Credits   unstable    api     quadrant:q3

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
    Run Donations Batch Process
    Go To Page                              Details                              Contact
    ...                                     object_id=${data}[contact][Id]
    Navigate To And Validate Field Value    Soft Credit This Year                contains    $50.00    section=Soft Credit Total
    Navigate To And Validate Field Value    Soft Credit Total                    contains    $50.00    section=Soft Credit Total