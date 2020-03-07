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
Suite Teardown  Delete Records and Close Browser

***Keywords***
Setup Test Data
    &{contact1} =  API Create Contact    Email=skristem@robot.com
    Set suite variable                   &{contact1}
    &{contact2} =  API Create Contact    Email=skristem@robot.com
    Set suite variable                   &{contact2}
    &{contact3} =  API Create Contact    AccountId=&{contact1}[AccountId]
    Set suite variable                   &{contact3}
    

*** Test Cases ***

Create ASC for Related Contact
    [tags]                                  feature:Automated Soft Credits       W-039819
    Go To Page                              Details                              Contact                                
    ...                                     object_id=&{contact1}[Id]
    Select Tab                              Related
    Click Related List Button               Relationships                        New
    Wait For Modal                          New                                  Relationship
    Populate Lookup Field                   Related Contact                      &{contact2}[FirstName] &{contact2}[LastName]
    Select Value From Dropdown              Type                                 Employer
    Select Value From Dropdown              Related Opportunity Contact Role     Soft Credit
    Click Modal Button                      Save
    Wait Until Modal Is Closed
    Click Related List Button               Relationships                        New
    Wait For Modal                          New                                  Relationship
    Populate Lookup Field                   Related Contact                      &{contact3}[FirstName] &{contact3}[LastName]
    Select Value From Dropdown              Type                                 Coworker
    Select Value From Dropdown              Related Opportunity Contact Role     Solicitor
    Click Modal Button                      Save
    Wait Until Modal Is Closed
    #&{relation} =  API Create Relationship    &{contact1}[Id]    &{contact3}[Id]    Coworker    ${ns}Related_Opportunity_Contact_Role__c=Solicitor
    &{opportunity} =                        API Create Opportunity               &{Contact1}[AccountId]    Donation    
    ...                                     Name=&{Contact1}[FirstName] $100 donation    
    ...                                     Amount=100
    Go To Page                              Details                              Opportunity                                
    ...                                     object_id=&{opportunity}[Id]
    Select Tab                              Related
    Select Relatedlist                      Contact Roles
    Wait For Page Object                    Custom                               OpportunityContactRole
    Verify Related List Field Values
    ...                                     &{contact1}[FirstName] &{contact1}[LastName]=Donor
    ...                                     &{contact2}[FirstName] &{contact2}[LastName]=Soft Credit
    ...                                     &{contact3}[FirstName] &{contact3}[LastName]=Solicitor
    Go To Page                              Details                              Contact                                
    ...                                     object_id=&{contact2}[Id]
    Select Tab                              Related
    Check Record Related Item               Opportunities                        &{opportunity}[Name]
    Go To Page                              Details                              Contact                                
    ...                                     object_id=&{contact3}[Id]
    Select Tab                              Related
    Check Record Related Item               Opportunities                        &{opportunity}[Name]
    Run Donations Batch Process
    Go To Page                              Details                              Contact                                
    ...                                     object_id=&{Contact2}[Id]
    Navigate To And Validate Field Value    Soft Credit This Year    contains    $100.00    section=Soft Credit Total
    Navigate To And Validate Field Value    Soft Credit Total        contains    $100.00    section=Soft Credit Total
    Go To Page                              Details                              Contact                                
    ...                                     object_id=&{Contact3}[Id]
    Navigate To And Validate Field Value    Soft Credit This Year    contains    $0.00    section=Soft Credit Total
    Navigate To And Validate Field Value    Soft Credit Total        contains    $0.00    section=Soft Credit Total
