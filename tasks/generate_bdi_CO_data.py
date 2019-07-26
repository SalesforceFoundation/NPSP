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
