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

Setup Test Data
# Set up all the required data for the test based on the keyword requests
    &{data} =  Setup Data
               ...           contact1=&{contact1_fields}
               ...           contact2 linkedto contact1=&{contact2_fields}
               ...           opportunity for contact1=&{opportunity1_fields}
               ...           opportunity for contact2=&{opportunity2_fields}

    Set suite variable    &{data}


*** Variables ***
&{contact1_fields}         Email=test@example.com
&{contact2_fields}         Email=test2@example.com
&{opportunity1_fields}     Type=Donation   Name=Delete test $100 Donation   Amount=100  StageName=Closed Won
&{opportunity2_fields}     Type=Donation   Name=Rollup test $50 donation    Amount=50   StageName=Closed Won    Primary_Contact=contact2

*** Test Cases ***

Create Donation from Contact and Verify Contact Roles on Opportunity Page

    [tags]                                 W-038461                 feature:Donations

    Go To Page                             Details
    ...                                    Opportunity
    ...                                    object_id=&{data}[contact1opportunityid]


    Select Tab                             Related

    Validate Values Under Relatedlist For  Contact Roles           &{data}[contact1_FirstName] &{data}[contact1_LastName]=Donor
    ...                                                            &{data}[contact2_FirstName] &{data}[contact2_LastName]=Household Member

    Go To Page                             Details
    ...                                    Contact
    ...                                    object_id=&{data}[contact1_AccountId]

    Select Tab                             Details

    # Perform the below Validations

    Validate Field Value Under Section     Membership Information    Total Gifts                 $150.00
    Validate Field Value Under Section     Membership Information    Total Number of Gifts       2

   # Run the batch process to obtain all the soft credits
    Run Donations Batch Process

    Go To Page                             Details
    ...                                    Contact
    ...                                    object_id=&{data}[contact1_Id]

    Validate Field Value Under Section     Soft Credit Total          Total Gifts                  $100.00
    Validate Field Value Under Section     Soft Credit Total          Total Number of Gifts        1

    Validate Field Value Under Section     Household Donation Info    Soft Credit Total             $50.00
    Validate Field Value Under Section     Household Donation Info    Total Number of Gifts         1

