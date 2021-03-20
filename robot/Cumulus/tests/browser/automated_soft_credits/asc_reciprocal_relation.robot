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
    Setupdata                   contact1               ${contact1_fields}
    &{contact2_fields} =	    Create Dictionary      Email=test2@example.com                   AccountId=${data}[contact1][AccountId]
    Setupdata                   contact2               ${contact2_fields}
    ${ns} =                     Get NPSP Namespace Prefix
    Set suite variable          ${ns}
    API Create Relationship     ${data}[contact1][Id]  ${data}[contact2][Id]    Coworker         ${ns}Related_Opportunity_Contact_Role__c=Soft Credit
    &{opportunity1_fields} =	Create Dictionary      AccountId=${data}[contact2][AccountId]    Type=Donation    Name=Reciprocal test $500 donation    Amount=500    StageName=Closed Won    ${ns}Primary_Contact__c=${data}[contact2][Id]
    Setupdata                   contact2               None                     ${opportunity1_fields}

    Setupdata                   contact3               ${contact3_fields}
    &{contact4_fields} =	    Create Dictionary      Email=test4@example.com  AccountId=${data}[contact3][AccountId]
    Setupdata                   contact4               ${contact4_fields}
    API Create Relationship     ${data}[contact3][Id]  ${data}[contact4][Id]    Coworker         ${ns}Related_Opportunity_Contact_Role__c=Soft Credit

*** Variables ***

&{contact1_fields}  Email=test1@example.com
&{contact3_fields}  Email=test3@example.com

*** Test Cases ***
ASC Reciprocal Relationship Test Case 1
    [Documentation]            Create 2 contacts on same household and Create relationship with contact2 and Related OCR as Soft Credit via API.
    ...                        Create an opp with contact2 as primary.Verify contact2 is Donor, contact1 is HH member(as no RelatedOCR set on reciprocal relation)
    ...                        After running donations batch job verify contact1 gets soft credits and contact2 gets only hard credits (no soft credits)
    [tags]                     feature:Automated Soft Credits       W-039819        unstable               notonfeaturebranch
    Go To Page                              Details                              Opportunity
    ...                                     object_id=${data}[contact2_opportunity][Id]
    Select Tab                              Related
    Select Relatedlist                      Contact Roles
    Verify Related List Field Values
    ...                                     ${data}[contact2][FirstName] ${data}[contact2][LastName]=Donor
    ...                                     ${data}[contact1][FirstName] ${data}[contact1][LastName]=Household Member
    Run Donations Batch Process
    Go To Page                              Details                              Contact
    ...                                     object_id=${data}[contact1][Id]
    Navigate To And Validate Field Value    Soft Credit This Year                contains    $500.00    section=Soft Credit Total
    Navigate To And Validate Field Value    Soft Credit Total                    contains    $500.00    section=Soft Credit Total
    Go To Page                              Details                              Contact
    ...                                     object_id=${data}[contact2][Id]
    Navigate To And Validate Field Value    Total Gifts This Year                contains    $500.00    section=Soft Credit Total
    Navigate To And Validate Field Value    Total Gifts                          contains    $500.00    section=Soft Credit Total
    Navigate To And Validate Field Value    Soft Credit This Year                contains    $0.00      section=Soft Credit Total
    Navigate To And Validate Field Value    Soft Credit Total                    contains    $0.00      section=Soft Credit Total

Test Case 2
    [Documentation]            Create 2 contacts on same household and Create relationship with contact2 and Related OCR as Soft Credit via API.
    ...                        On the reciprocal relation add Related Opp contact role as Soft Credit.Create an opp with contact1 as primary.
    ...                        Verify contact1 is Donor, contact2 has soft credit role. Run donations batch job
    ...                        verify contact1 gets hard credits and no soft credits, contact2 gets soft credits
    [tags]                     feature:Automated Soft Credits       W-039819    unstable

    Go To Page                              Details                              Contact
    ...                                     object_id=${data}[contact4][Id]
    Select Tab  Related
    Click Related Table Item Link           Relationships                        ${data}[contact3][FirstName] ${data}[contact3][LastName]
    Edit Record Dropdown Value             	Related Opportunity Contact Role     Soft Credit
    Save Record
    &{opportunity2} =                       API Create Opportunity               ${data}[contact3][AccountId]    Donation
    ...                                     Name=Reciprocal test $500 donation
    ...                                     Amount=500
    ...                                     ${ns}Primary_Contact__c=${data}[contact3][Id]
    Go To Page                              Details                              Opportunity
    ...                                     object_id=${opportunity2}[Id]
    Select Tab                              Related
    Select Relatedlist                      Contact Roles
    Verify Related List Field Values
    ...                                     ${data}[contact3][FirstName] ${data}[contact3][LastName]=Donor
    ...                                     ${data}[contact4][FirstName] ${data}[contact4][LastName]=Soft Credit
    Run Donations Batch Process
    Go To Page                              Details                              Contact
    ...                                     object_id=${data}[contact4][Id]
    Navigate To And Validate Field Value    Soft Credit This Year    contains    $500.00    section=Soft Credit Total
    Navigate To And Validate Field Value    Soft Credit Total        contains    $500.00    section=Soft Credit Total
    Go To Page                              Details                              Contact
    ...                                     object_id=${data}[contact3][Id]
    Navigate To And Validate Field Value    Total Gifts This Year    contains    $500.00    section=Soft Credit Total
    Navigate To And Validate Field Value    Total Gifts              contains    $500.00    section=Soft Credit Total
    Navigate To And Validate Field Value    Soft Credit This Year    contains    $0.00      section=Soft Credit Total
    Navigate To And Validate Field Value    Soft Credit Total        contains    $0.00      section=Soft Credit Total
