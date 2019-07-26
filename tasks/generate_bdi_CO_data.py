import math
from datetime import date, datetime

from factory.alchemy import SQLAlchemyModelFactory
import factory
from .factory_utils import Adder, SessionBase, Factories
from .data_generation_base import BatchDataTask

START_DATE = date(2019, 1, 1)  # Per https://salesforce.quip.com/gLfGAPtqVzUS


def now():
    return datetime.now().date()


class GenerateBDIData_CO(BatchDataTask):
    """Generate data specific to the Honeybees test cases"""
    def generate_data(self, session, engine, base, num_records):
        """ Per
        https://salesforce.quip.com/gLfGAPtqVzUS
        """
        print("NUMRECORDS", num_records)
        factories = make_factories(session, base.classes, SQLAlchemyModelFactory)
        batch_size = math.floor(num_records / 4)  
        make_records(batch_size, factories)


def make_factories(session, classes, Factory):
    """Function that creates factories attached to the right
       database.

       The specification for the factories is defined in
       https://salesforce.quip.com/gLfGAPtqVzUS """
    BaseMeta = SessionBase(session)

    class DataImport(Factory):
        class Meta(BaseMeta):
            model = classes.npsp__DataImport__c

        class Params:
            counter = "Adder not set"

        id = factory.Sequence(lambda n: n + 1)
        npsp__Donation_Amount__c = factory.LazyAttribute(lambda o: o.counter(1) * 100)
        npsp__Donation_Date__c = now()
        npsp__GAU_Allocation_1_Percent__c = 10
        npsp__CO1_Date__c = now()
        npsp__CO1_currency__c = 100
        npsp__ASC_Amount__c = 100
        npsp__CO1_Number__c = 1
        npsp__CO1_Picklist__c = factory.Sequence(lambda i: f"Option{(i%4) + 1}")
        npsp__CO1_Phone__c = 123
        npsp__CO1_textarea__c = "Long text"
        npsp__CO1_url__c = "http://www.url.com/"
        npsp__CO1_text2__c = factory.LazyAttribute(lambda o: f"text{o.counter(0)}")
        npsp__CO2_Currency2__c = 200   # ## CHECK THIS ONE IS FIXED
        npsp__CO3_Text__c = factory.LazyAttribute(lambda o: f"text{o.counter(0)}")
        npsp__CO3_Date__c = now()
        npsp__CO3_Currency__c = 100
        npsp__CO3_Number__c = 1
        npsp__CO3_Picklist__c = factory.Sequence(lambda i: f"Option{(i%3) + 1}")
        npsp__CO3_Phone__c = 123
        npsp__WO_RecommendedCrewSize__c = 10
        npsp__WO_SuggestedMaintenanceDate__c = now()
        npsp__WO_Subject__c = "test1"
        npsp__ASC_Role__c = "match"   ####  FIXME
        npsp__ASC_Role__c = "Option1"   ####  FIXME

    class GAU(Factory):
        class Meta(BaseMeta):
            model = classes.npsp__General_Accounting_Unit__c
    
        id = factory.Sequence(lambda n: n + 1)

    return Factories(session, vars())


def make_records(batch_size, factories):
    """Make the 4 batches of DIs described here:
    https://salesforce.quip.com/YfOpAwKbhcat
     """
    def create_batch(classname, **kwargs):
        factories.create_batch(classname, batch_size, **kwargs)

    gau = factories["GAU"].create(Name="Scholarship")

    create_batch(
        "DataImport",
        counter=Adder(0),
        npsp__Donation_Donor__c="Account1",
        npsp__Opp_Do_Not_Automatically_Create_Payment__c=True,
        npsp__Account1_Name__c=factory.LazyAttribute(lambda o: f"Account {o.counter(0)}"),
        npsp__Opportunity_Contact_Role_1_Role__c="X",
        npsp__CO1_Text__c=factory.LazyAttribute(lambda o: f"Account {o.counter(0)}"),
        npsp__GAU_Allocation_1_GAU__c=gau.id,
    )
    create_batch(
        "DataImport",
        counter=Adder(0),
        npsp__Donation_Donor__c="Account1",
        npsp__Opp_Do_Not_Automatically_Create_Payment__c=False,
        npsp__Contact1_Lastname__c=factory.LazyAttribute(lambda o: f"Contact{o.counter(0)}"),
        npsp__Opportunity_Contact_Role_1_Role__c="Influencer",
        npsp__CO1_Text__c=factory.LazyAttribute(lambda o: f"Account {o.counter(0)}"),
        npsp__GAU_Allocation_1_GAU__c=gau.id,
    )
    create_batch(
        "DataImport",
        counter=Adder(0),
        npsp__Donation_Donor__c="Contact1",
        npsp__Opp_Do_Not_Automatically_Create_Payment__c=True,
        npsp__Account1_Name__c=factory.LazyAttribute(lambda o: f"Account {o.counter(0)}"),
        npsp__Opportunity_Contact_Role_1_Role__c="X",
        npsp__CO1_Text__c=factory.LazyAttribute(lambda o: f"Account {o.counter(0)}"),
        npsp__GAU_Allocation_1_GAU__c=gau.id,
    )
    create_batch(
        "DataImport",
        counter=Adder(0),
        npsp__Donation_Donor__c="Contact1",
        npsp__Opp_Do_Not_Automatically_Create_Payment__c=False,
        npsp__Account1_Name__c=factory.LazyAttribute(lambda o: f"Account {o.counter(0)}"),
        npsp__Opportunity_Contact_Role_1_Role__c="X",
        npsp__CO1_Text__c=factory.LazyAttribute(lambda o: f"Account {o.counter(0)}"),
        npsp__GAU_Allocation_1_GAU__c=gau.id,
    )


fields = """
            <fullName>Account1ImportStatus__c</fullName>
        <fullName>Account1Imported__c</fullName>
        <fullName>Account1_City__c</fullName>
        <fullName>Account1_Country__c</fullName>
        <fullName>Account1_Name__c</fullName>
        <fullName>Account1_Phone__c</fullName>
        <fullName>Account1_State_Province__c</fullName>
        <fullName>Account1_Street__c</fullName>
        <fullName>Account1_Website__c</fullName>
        <fullName>Account1_Zip_Postal_Code__c</fullName>
        <fullName>Account2ImportStatus__c</fullName>
        <fullName>Account2Imported__c</fullName>
        <fullName>Account2_City__c</fullName>
        <fullName>Account2_Country__c</fullName>
        <fullName>Account2_Name__c</fullName>
        <fullName>Account2_Phone__c</fullName>
        <fullName>Account2_State_Province__c</fullName>
        <fullName>Account2_Street__c</fullName>
        <fullName>Account2_Website__c</fullName>
        <fullName>Account2_Zip_Postal_Code__c</fullName>
        <fullName>ApexJobId__c</fullName>
        <fullName>Campaign_Member_Status__c</fullName>
        <fullName>Contact1ImportStatus__c</fullName>
        <fullName>Contact1Imported__c</fullName>
        <fullName>Contact1_Alternate_Email__c</fullName>
        <fullName>Contact1_Birthdate__c</fullName>
        <fullName>Contact1_Firstname__c</fullName>
        <fullName>Contact1_Home_Phone__c</fullName>
        <fullName>Contact1_Lastname__c</fullName>
        <fullName>Contact1_Mobile_Phone__c</fullName>
        <fullName>Contact1_Other_Phone__c</fullName>
        <fullName>Contact1_Personal_Email__c</fullName>
        <fullName>Contact1_Preferred_Email__c</fullName>
                    <fullName>Personal</fullName>
                    <fullName>Work</fullName>
                    <fullName>Alternate</fullName>
        <fullName>Contact1_Preferred_Phone__c</fullName>
                    <fullName>Home</fullName>
                    <fullName>Work</fullName>
                    <fullName>Mobile</fullName>
                    <fullName>Other</fullName>
        <fullName>Contact1_Salutation__c</fullName>
        <fullName>Contact1_Title__c</fullName>
        <fullName>Contact1_Work_Email__c</fullName>
        <fullName>Contact1_Work_Phone__c</fullName>
        <fullName>Contact2ImportStatus__c</fullName>
        <fullName>Contact2Imported__c</fullName>
        <fullName>Contact2_Alternate_Email__c</fullName>
        <fullName>Contact2_Birthdate__c</fullName>
        <fullName>Contact2_Firstname__c</fullName>
        <fullName>Contact2_Home_Phone__c</fullName>
        <fullName>Contact2_Lastname__c</fullName>
        <fullName>Contact2_Mobile_Phone__c</fullName>
        <fullName>Contact2_Other_Phone__c</fullName>
        <fullName>Contact2_Personal_Email__c</fullName>
        <fullName>Contact2_Preferred_Email__c</fullName>
                    <fullName>Personal</fullName>
                    <fullName>Work</fullName>
                    <fullName>Alternate</fullName>
        <fullName>Contact2_Preferred_Phone__c</fullName>
                    <fullName>Home</fullName>
                    <fullName>Work</fullName>
                    <fullName>Mobile</fullName>
                    <fullName>Other</fullName>
        <fullName>Contact2_Salutation__c</fullName>
        <fullName>Contact2_Title__c</fullName>
        <fullName>Contact2_Work_Email__c</fullName>
        <fullName>Contact2_Work_Phone__c</fullName>
        <fullName>DonationImportStatus__c</fullName>
        <fullName>DonationImported__c</fullName>
        <fullName>Donation_Amount__c</fullName>
        <fullName>DonationCampaignImported__c</fullName>
        <fullName>DonationCampaignImportStatus__c</fullName>
        <fullName>Donation_Campaign_Name__c</fullName>
        <fullName>Donation_Date__c</fullName>
        <fullName>Donation_Description__c</fullName>
        <fullName>Donation_Donor__c</fullName>
                    <fullName>Contact1</fullName>
                    <fullName>Account1</fullName>
        <fullName>Donation_Member_Level__c</fullName>
        <fullName>Donation_Membership_End_Date__c</fullName>
        <fullName>Donation_Membership_Origin__c</fullName>
        <fullName>Donation_Membership_Start_Date__c</fullName>
        <fullName>Donation_Name__c</fullName>
        <fullName>Donation_Possible_Matches__c</fullName>
        <fullName>Donation_Record_Type_Name__c</fullName>
        <fullName>Donation_Stage__c</fullName>
        <fullName>Donation_Type__c</fullName>
        <fullName>FailureInformation__c</fullName>
        <fullName>GAU_Allocation_1_Amount__c</fullName>
        <fullName>GAU_Allocation_1_GAU__c</fullName>
        <fullName>GAU_Allocation_1_Import_Status__c</fullName>
        <fullName>GAU_Allocation_1_Imported__c</fullName>
        <fullName>GAU_Allocation_1_Percent__c</fullName>
        <fullName>GAU_Allocation_2_Amount__c</fullName>
        <fullName>GAU_Allocation_2_GAU__c</fullName>
        <fullName>GAU_Allocation_2_Import_Status__c</fullName>
        <fullName>GAU_Allocation_2_Imported__c</fullName>
        <fullName>GAU_Allocation_2_Percent__c</fullName>
        <fullName>HomeAddressImportStatus__c</fullName>
        <fullName>HomeAddressImported__c</fullName>
        <fullName>Home_City__c</fullName>
        <fullName>Home_Country__c</fullName>
        <fullName>Home_State_Province__c</fullName>
        <fullName>Home_Street__c</fullName>
        <fullName>Home_Zip_Postal_Code__c</fullName>
        <fullName>HouseholdAccountImported__c</fullName>
        <fullName>Household_Phone__c</fullName>
        <fullName>ImportedDate__c</fullName>
        <fullName>NPSP_Data_Import_Batch__c</fullName>
        <fullName>Opportunity_Contact_Role_1_ImportStatus__c</fullName>
        <fullName>Opportunity_Contact_Role_1_Imported__c</fullName>
        <fullName>Opportunity_Contact_Role_1_Role__c</fullName>
        <fullName>Opportunity_Contact_Role_2_ImportStatus__c</fullName>
        <fullName>Opportunity_Contact_Role_2_Imported__c</fullName>
        <fullName>Opportunity_Contact_Role_2_Role__c</fullName>
        <fullName>PaymentImportStatus__c</fullName>
        <fullName>PaymentImported__c</fullName>
        <fullName>Payment_Check_Reference_Number__c</fullName>
        <fullName>Payment_Method__c</fullName>
        <fullName>Payment_Possible_Matches__c</fullName>
        <fullName>Status__c</fullName>
                    <fullName>Imported</fullName>
                    <fullName>Dry Run - Validated</fullName>
                    <fullName>Dry Run - Error</fullName>
                    <fullName>Failed</fullName>
        <fullName>All</fullName>
        <fullName>Dry_Run_Errors</fullName>
        <fullName>Dry_Run_Validated</fullName>
        <fullName>Failed_Data_Imports</fullName>
        <fullName>Succesfully_Imported</fullName>
        <fullName>To_Be_Imported</fullName>
        <fullName>Delete_All_Data_Import_Records</fullName>
        <fullName>Delete_Imported_Data_Import_Records</fullName>
        <fullName>Process_Data_Import</fullName>

        <fullName>Custom_add_date__c</fullName>
        <fullName>custom_acc_text__c</fullName>
        <fullName>custom_cont_num__c</fullName>
        <fullName>new_lookup_campaign__c</fullName>
        <fullName>custom_currency__c</fullName>
        <fullName>custom_date__c</fullName>
        <fullName>custom_email__c</fullName>
        <fullName>custom_multipick__c</fullName>
                    <fullName>1</fullName>
                    <fullName>2</fullName>
                    <fullName>3</fullName>
                    <fullName>4</fullName>
        <fullName>custom_number__c</fullName>
        <fullName>custom_phone__c</fullName>
        <fullName>custom_picklist__c</fullName>
                    <fullName>1</fullName>
                    <fullName>2</fullName>
                    <fullName>3</fullName>
                    <fullName>4</fullName>
        <fullName>custom_text__c</fullName>
        <fullName>custom_textarea__c</fullName>
        <fullName>custom_url__c</fullName>
        <fullName>CO1_Date__c</fullName>
        <fullName>CO1_Number__c</fullName>
        <fullName>CO1_Phone__c</fullName>
        <fullName>CO1_Picklist__c</fullName>
                    <fullName>Option1</fullName>
                    <fullName>Option2</fullName>
                    <fullName>Option3</fullName>
                    <fullName>Option4</fullName>
        <fullName>CO1_Text__c</fullName>
        <fullName>CO1_currency__c</fullName>
        <fullName>CO1_text2__c</fullName>
        <fullName>CO1_textarea__c</fullName>
        <fullName>CO1_url__c</fullName>
        <fullName>CO2_Currency2__c</fullName>
        <fullName>CO3_Currency__c</fullName>
        <fullName>CO3_Date__c</fullName>
        <fullName>CO3_Number__c</fullName>
        <fullName>CO3_Phone__c</fullName>
        <fullName>CO3_Picklist__c</fullName>
                    <fullName>Option1</fullName>
                    <fullName>Option2</fullName>
                    <fullName>Option3</fullName>
        <fullName>CO3_Text__c</fullName>
        <fullName>WO_RecommendedCrewSize__c</fullName>
        <fullName>WO_Subject__c</fullName>
        <fullName>WO_SuggestedMaintenanceDate__c</fullName>
        <fullName>WorkOrderImportStatus__c</fullName>
        <fullName>WorkOrderImported__c</fullName>
"""