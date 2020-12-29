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
    # Create contact1
    Setupdata   contact1   ${contact1_fields}

    # Create contact2 linked to contact1's household
    &{contact2_fields} =	Create Dictionary  Email=test2@example.com  AccountId=${data}[contact1][AccountId]
    Setupdata   contact2   ${contact2_fields}

    ${ns} =  Get NPSP Namespace Prefix
    &{opportunity2_fields} =	Create Dictionary  Type=Donation   Name=Rollup test $50 donation    Amount=50   StageName=Closed Won   ${ns}Primary_Contact__c=${data}[contact2][Id]

    # Setup an opportunity for contact1 and contact2
    Setupdata   contact1   None     ${opportunity1_fields}
    Setupdata   contact2   None     ${opportunity2_fields}

*** Variables ***
&{contact1_fields}         Email=test@example.com
&{opportunity1_fields}     Type=Donation   Name=Delete test $100 Donation   Amount=100  StageName=Closed Won

*** Test Cases ***

Create Donation from Contact and Verify Contact Roles on Opportunity Page

    [tags]                                 W-038461                 feature:Donations

    Go To Page                             Detail
    ...                                    Opportunity
    ...                                    object_id=${data}[contact1_opportunity][Id]

    Select Tab                             Related

    Verify Related List Field Values       Contact Roles           ${data}[contact1][FirstName] ${data}[contact1][LastName]=Donor
    ...                                                            ${data}[contact2][FirstName] ${data}[contact2][LastName]=Household Member

    Go To Page                             Details
    ...                                    Account
    ...                                    object_id=${data}[contact1][AccountId]

    Select Tab                             Details

    # Perform the below Validations on the Account details page
    Navigate To And Validate Field Value         Total Gifts               contains          $150.00    Membership Information
    Navigate To And Validate Field Value         Total Number of Gifts     contains          2          Membership Information

    # Run the batch process to obtain all the soft credits
    Run Donations Batch Process

    # Navigate to the contact details page of the non primary contact and perform the below validations
    Go To Page                             Details
    ...                                    Account
    ...                                    object_id=${data}[contact1][Id]

    Navigate To And Validate Field Value     Total Gifts              contains     $100.00            Soft Credit Total
    Navigate To And Validate Field Value     Total Number of Gifts    contains     1                  Soft Credit Total

    Navigate To And Validate Field Value     Soft Credit Total        contains      $50.00            Household Donation Info
    Navigate To And Validate Field Value     Total Number of Gifts    contains      1                 Household Donation Info

