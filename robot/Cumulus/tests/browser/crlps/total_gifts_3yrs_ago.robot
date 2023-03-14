*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/NPSPSettingsPageObject.py
...             robot/Cumulus/resources/ContactPageObject.py
...             robot/Cumulus/resources/CustomizableRollupsPageObject.py
...             robot/Cumulus/resources/ObjectMangerPageObject.py
Suite Setup     Run Keywords
...             Open Test Browser
...             Setup Test Data
...             Enable Customizable Rollups
Suite Teardown  Capture Screenshot and Delete Records and Close Browser

*** Keywords ***
Setup Test Data
    Create Customfield In Object Manager
    ...                                                    Object=Contact
    ...                                                    Field_Type=Currency
    ...                                                    Field_Name=Total Gifts Three Years Ago

*** Test Cases ***
Calculate CRLPs for Total Gifts 3 Years Ago
    [Documentation]             Create a New rollup for Total Gifts 3 years ago by cloning an existing rollup called Total Gifts Two Years Ago
    ...                         and create an opportunity for 3 ago from current date and verify the rollup value on newly created Total Gifts Three Years Ago field
    [tags]                      feature:CRLP   unstable    api      quadrant:q3

# clone an existing rollup and create a new one and verify that its created
    Load Page Object            Custom   CustomRollupSettings
    Navigate To Crlpsettings
    Clone Rollup                Contact: Total Gifts Two Years Ago
    ...                                                   Target Object=Contact
    ...                                                   Target Field=Total Gifts Three Years Ago
    ...                                                   Description=The total of all gifts three calendar years ago where the Contact is the Opportunity Primary Contact.
    ...                                                   Operation=Sum
    ...                                                   Years Ago=3 Years Ago

    Verify Rollup exists        Contact: Total Gifts Three Years Ago

# create a contact and opportunity via API and verify new rollup is working
    &{contact} =         API Create Contact       FirstName=${faker.first_name()}    LastName=${faker.last_name()}
    ${date} =            Get Current Date         result_format=%Y-%m-%d             increment=-1098 days
    &{opportunity} =     API Create Opportunity   ${contact}[AccountId]              Donation
    ...    StageName=Closed Won
    ...    Amount=3000
    ...    CloseDate=${date}
    ...    npe01__Do_Not_Automatically_Create_Payment__c=false
    ...    Name=${contact}[Name] $3000 Donation
    Go To Page                                    Details
    ...                                           Contact
    ...                                           object_id=${contact}[Id]
    Verify Rollup Field Value                     Total Gifts Three Years Ago         $3,000.00     section=Contact Information