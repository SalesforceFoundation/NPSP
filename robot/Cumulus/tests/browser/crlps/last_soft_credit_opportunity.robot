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
Suite Teardown  Capture Screenshot and Delete Records and Close Browser

*** Keywords ***
# creates test data a contact and an opportunity for the contact
Setup Test Data
    Setupdata   contact   ${contact1_fields}     ${opportunity_fields}
    ${date} =   Get Current Date       result_format=%-m/%-d/%Y
    Set suite variable    ${date}

*** Variables ***
&{contact1_fields}       Email=test@example.com
&{opportunity_fields}    Type=Donation   Name=Customizable rollup test $100 Donation   Amount=100  StageName=Closed Won  npe01__Do_Not_Automatically_Create_Payment__c=false

*** Test Cases ***

Create Crlp For Automated Soft Credit
    [Documentation]     This testcase is to ensure customizable rollups are working for Last soft credit opportunity
    ...                 Create the required lookup customfield on contact object -(https://foundation.lightning.force.com/lightning/r/agf__ADM_Work__c/a2x1E000001HpCOQA0/view)
    ...                 Enable CRLP from settings, create a setting record. Create an opportunity associated with a contact that is not primary
    ...                 Run the relevant rollup batch job and ensure that rollups are happening and displayed on the opportunity page

    [tags]              feature:CRLP   unstable    api      quadrant:q3

    # Create a custom lookup field requried for this particular testcase
    Create Customfield In Object Manager
    ...                                                    Object=Contact
    ...                                                    Field_Type=Lookup
    ...                                                    Field_Name=Last Soft Credit Opportunity
    ...                                                    Related_To=Opportunity
    Enable Customizable Rollups

    # Create a crlp settings record for the field last soft credit opportuntiy
    Load Page Object                                       Custom                          CustomRollupSettings
    Navigate To Crlpsettings
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

    # Navigate to Contact page and run Batch Process
    Go To Page                                            Details
    ...                                                   Contact
    ...                                                   object_id=${data}[contact][Id]
    Run Donations Batch Process

    # Navigate to the contact page and asset that the rollup for the last soft credit opportunity occured
    Go To Page                                            Details
    ...                                                   Contact
    ...                                                   object_id=${data}[contact][Id]
    Wait Until Loading Is Complete
    Reload Page
    Verify Rollup Field Value                             Last Soft Credit Opportunity         Customizable rollup test $100 Donation   section=Contact Information
