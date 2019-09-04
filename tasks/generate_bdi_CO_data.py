import math
from datetime import date, datetime

import factory
from .factory_utils import Adder, ModuleDataFactory, Models


def now():
    return datetime.now().date()


START_DATE = date(2019, 1, 1)  # Per https://salesforce.quip.com/gLfGAPtqVzUS


class GenerateBDIData_CO(ModuleDataFactory):
    """Generate data specific to the Honeybees test cases"""
    def make_records(self, num_records, factories):
        """Make the 4 batches of DIs described here:
        https://salesforce.quip.com/YfOpAwKbhcat
        """
        batch_size = math.floor(num_records / 4)

        def create_batch(classname, **kwargs):
            factories.create_batch(classname, batch_size, **kwargs)

        gau = factories["GAU"].create(Name="Scholarship")
        # maintenance_plan = factories["MaintenancePlan"].create()
        create_batch(
            "DataImport",
            counter=Adder(0),
            Donation_Donor__c="Account1",
            Opp_Do_Not_Automatically_Create_Payment__c=False,
            Account1_Name__c=factory.LazyAttribute(lambda o: f"Account {o.counter(0)}"),
            CO1_Text__c=factory.LazyAttribute(lambda o: f"Account {o.counter(0)}"),
            GAU_Allocation_1_GAU__c=gau.id,
            # WO_MaintenancePlan__c=maintenance_plan.id,
        )
        create_batch(
            "DataImport",
            counter=Adder(0),
            Donation_Donor__c="Account1",
            Opp_Do_Not_Automatically_Create_Payment__c=False,
            Account1_Name__c=factory.LazyAttribute(lambda o: f"Account{o.counter(0)}"),
            CO1_Text__c=factory.LazyAttribute(lambda o: f"text{o.counter(0)}"),
            GAU_Allocation_1_GAU__c=gau.id,
            # WO_MaintenancePlan__c=maintenance_plan.id,
        )
        create_batch(
            "DataImport",
            counter=Adder(0),
            Donation_Donor__c="Contact1",
            Opp_Do_Not_Automatically_Create_Payment__c=False,
            Contact1_Lastname__c=factory.LazyAttribute(lambda o: f"Contact {o.counter(0)}"),
            Opportunity_Contact_Role_1_Role__c="Influencer",
            CO1_Text__c=factory.LazyAttribute(lambda o: f"text{o.counter(0)}"),
            GAU_Allocation_1_GAU__c=gau.id,
            # WO_MaintenancePlan__c=maintenance_plan.id,
        )
        create_batch(
            "DataImport",
            counter=Adder(0),
            Donation_Donor__c="Contact1",
            Opp_Do_Not_Automatically_Create_Payment__c=False,
            Contact1_Lastname__c=factory.LazyAttribute(lambda o: f"Contact{o.counter(0)}"),
            Opportunity_Contact_Role_1_Role__c="Influencer",
            CO1_Text__c=factory.LazyAttribute(lambda o: f"text{o.counter(0)}"),
            GAU_Allocation_1_GAU__c=gau.id,
            # WO_MaintenancePlan__c=maintenance_plan.id,
        )


# class MaintenancePlan(factory.alchemy.SQLAlchemyModelFactory):
#     class Meta:
#         model = Models.MaintenancePlan

#     id = factory.Sequence(lambda n: n + 1)
#     Frequency = 5
#     GenerationTimeframe = 10
#     StartDate = now()
#     NextSuggestedMaintenanceDate = now()


class DataImport(factory.alchemy.SQLAlchemyModelFactory):
    class Meta:
        model = Models.DataImport__c

    class Params:
        counter = "Adder not set"

    id = factory.Sequence(lambda n: n + 1)
    Donation_Amount__c = factory.LazyAttribute(lambda o: o.counter(1) * 100)
    Donation_Date__c = now()
    GAU_Allocation_1_Percent__c = 10
    CO1_Date__c = now()
    CO1_currency__c = 100
    CO1_Number__c = 1
    CO1_Picklist__c = factory.Sequence(lambda i: f"Option{(i%4) + 1}")
    CO1_Phone__c = 123
    CO1_textarea__c = "Long text"
    CO1_url__c = "http://www.url.com/"
    CO1_text2__c = factory.LazyAttribute(lambda o: f"text{o.counter(0)}")
    CO1_Currency2__c = 200   # ## CHECK THIS ONE IS FIXED
    CO3_Text__c = factory.LazyAttribute(lambda o: f"text{o.counter(0)}")
    CO3_Date__c = now()
    CO3_Currency__c = 100
    CO3_Number__c = 1
    CO3_Picklist__c = factory.Sequence(lambda i: f"Option{(i%3) + 1}")
    CO3_Phone__c = 123
    WO_MinimumCrewSize__c = 5
    WO_RecommendedCrewSize__c = 10
    WO_SuggestedMaintenanceDate__c = now()
    WO_Subject__c = factory.Sequence(lambda n: f"test{n + 1}")
    Contact1_Lastname__c = "Some Contact"
    Account1_Country__c = "Canada"
    Contact1_Title__c = "HRH"
    # ASC_Role__c = "match"
    # ASC_Amount__c = 100


class GAU(factory.alchemy.SQLAlchemyModelFactory):
    class Meta:
        model = Models.General_Accounting_Unit__c

    id = factory.Sequence(lambda n: n + 1)
