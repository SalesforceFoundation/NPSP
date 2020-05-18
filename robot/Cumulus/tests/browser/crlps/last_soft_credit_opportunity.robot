*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/ContactPageObject.py
...             robot/Cumulus/resources/NPSPSettingsPageObject.py
...             robot/Cumulus/resources/CustomizableRollupsPageObject.py
...             robot/Cumulus/resources/OpportunityPageObject.py
...             robot/Cumulus/resources/ObjectMangerPageObject.py
...             robot/Cumulus/resources/NPSP.py
Suite Setup     Run keywords
...             Open Test Browser
...             Setup Test Data
...             Validate And Create Required CustomField
#Suite Teardown  Delete Records and Close Browser

***Keywords***
# creates test data a contact and an opportunity for the contact
Setup Test Data
    Setupdata   contact   ${contact1_fields}     ${opportunity_fields}
    ${date} =   Get Current Date       result_format=%-m/%-d/%Y
    Set suite variable    ${date}

# Navigates to Object Manger for the specified object and checks for the presence of the custom field
# If the specified custom field is not present adds the custom field
Validate And Create Required CustomField
    load page object                                     Custom                           ObjectManager
    open fields and relationships                        Contact
    create custom field                                  Lookup
    ...                                                  Last Soft Credit Opportunity
    ...                                                  Opportunity

*** Variables ***
&{contact1_fields}       Email=test@example.com
&{opportunity_fields}    Type=Donation   Name=Customizable rollup test $100 Donation   Amount=100  StageName=Closed Won  npe01__Do_Not_Automatically_Create_Payment__c=false

*** Test Cases ***

Create Crlp For Automated Soft Credit
    [Documentation]

    [tags]                                               W-037650                         feature:Contacts and Accounts

    # Enable Crlp from the settings page if the crlp setting is not on
    Go To Page                                           Custom                           NPSP_Settings
    Open Main Menu                                       Donations
    Click Link With Text                                 Customizable Rollups
    Enable customizable rollups if not enabled

    # Create a crlp settings record for the field last soft credit opportuntiy
    Load Page Object                                      Custom                          CustomRollupSettings
    Loadcrlpsettings
    Create New Rollup Setting
    ...                                                   Target Object=Contact
    ...                                                   Target Field=Last Soft Credit Opportunity
    ...                                                   Description=A link to the most recent Opportunity for which the Contact received a soft credit.
    ...                                                   Operation=Last
    ...                                                   Rollup Type=Opportunity -> Contact (Soft Credit)
    ...                                                   Filter Group=Opps: Won (SC)
    ...                                                   Field to Roll Up=Opportunity: Opportunity ID

    # Navigate to the opportunity details page and make the contact associated not primary and set the role to soft credit

    Go To Page                                            Details
    ...                                                   Opportunity
    ...                                                   object_id=${data}[contact_opportunity][Id]
    Select Tab                                            Related
    Change Related Contact Role Settings                  ${data}[contact][FirstName]
    ...                                                   Soft Credit
    ...                                                   Primary=unchecked

    # Navigate to Contact page and run recalculate rollups option
    Go To Page                                            Details
    ...                                                   Contact
    ...                                                   object_id=${data}[contact][Id]
    Waitfor Actions Dropdown And Click Option             Recalculate Rollups
    Wait Until Loading Is Complete

    Go To Page                                            Listing                               Contact
    Page Should Contain Link                              ${data}[contact]{first_name} ${data}[contact]{last_name}
    Go To Page                                            Details
    ...                                                   Contact
    ...                                                   object_id=${data}[contact][Id]
    Wait Until Loading Is Complete
    Reload Page

    Wait Until Keyword Succeeds                           1 minute
        ...                                               5 seconds
        ...                                               Navigate To And Validate Field Value
        ...                                               Last Soft Credit Opportunity                contains         Customizable rollup test $100 Donation
