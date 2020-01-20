*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/ContactPageObject.py
...             robot/Cumulus/resources/AccountPageObject.py
...             robot/Cumulus/resources/OpportunityPageObject.py
...             robot/Cumulus/resources/NPSP.py
Suite Setup     Run keywords
...             Open Test Browser
...             Setup Test Data
Suite Teardown  Delete Records and Close Browser

***Keywords***


# Set up all the required data for the test based on the keyword requests
Setup Test Data
    # Create contact1
    Setupdata   contact1   ${contact1_fields}

    # Create contact2 linked to contact1's household
    &{contact2_fields} =	Create Dictionary  Email=test2@example.com  AccountId=${data}[contact1][AccountId]
    Setupdata   contact2   ${contact2_fields}

    # Setup an opportunity for contact1 and contact2
    Setupdata   contact1   None     ${opportunity1_fields}
    Setupdata   contact2   None     ${opportunity2_fields}

*** Variables ***
&{contact1_fields}         Email=test@example.com
&{opportunity1_fields}     Type=Donation   Name=Delete test $100 Donation   Amount=100  StageName=Closed Won
&{opportunity2_fields}     Type=Donation   Name=Rollup test $50 donation    Amount=50   StageName=Closed Won

*** Test Cases ***

Create Donation from Contact and Verify Contact Roles on Opportunity Page

    [tags]                                 W-038461                 feature:Donations

    Go To Page                             Detail
    ...                                    Opportunity
    ...                                    object_id=${data}[contact1_opportunity][Id]


    Select Tab                             Related

    Validate Values Under Relatedlist For  Contact Roles           ${data}[contact1][FirstName] ${data}[contact1][LastName]=Donor
    ...                                                            ${data}[contact2][FirstName] ${data}[contact2][LastName]=Household Member

    Go To Page                             Details
    ...                                    Contact
    ...                                    object_id=${data}[contact1][AccountId]

    Select Tab                             Details

    # Perform the below Validations

    Validate Field Value Under Section     Membership Information    Total Gifts                 $150.00
    Validate Field Value Under Section     Membership Information    Total Number of Gifts       2

    # Run the batch process to obtain all the soft credits
    Run Donations Batch Process

    Go To Page                             Details
    ...                                    Contact
    ...                                    object_id=${data}[contact1][Id]

    Validate Field Value Under Section     Soft Credit Total          Total Gifts                  $100.00
    Validate Field Value Under Section     Soft Credit Total          Total Number of Gifts        1

    Validate Field Value Under Section     Household Donation Info    Soft Credit Total             $50.00
    Validate Field Value Under Section     Household Donation Info    Total Number of Gifts         1

