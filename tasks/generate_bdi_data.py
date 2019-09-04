import math
from factory.alchemy import SQLAlchemyModelFactory
import factory
from .factory_utils import Adder, SessionBase, Factories
from datetime import date
from datetime import timedelta
from .data_generation_base import BatchDataTask

START_DATE = date(2019, 1, 1)  # Per https://salesforce.quip.com/gLfGAPtqVzUS


class GenerateBDIData(BatchDataTask):
    """Generate data specific to the Honeybees test cases"""
    def generate_data(self, session, engine, base, num_records):
        """ Per
        https://salesforce.quip.com/gLfGAPtqVzUS
        """
        factories = make_factories(session, base.classes, SQLAlchemyModelFactory)
        batch_size = math.floor(num_records / 20)  # 10000 / 20 = 500 as per https://salesforce.quip.com/gLfGAPtqVzUS#WNbACAukQAl
        make_preexisting_records(batch_size, factories)  # Per https://salesforce.quip.com/gLfGAPtqVzUS#WNbACAukQAl
        make_matching_import_records(batch_size, factories)  # Per https://salesforce.quip.com/gLfGAPtqVzUS#WNbACAHSe1L
        batch_size = math.floor(num_records / 8)  # 10000 / 8 = 1250 as per https://salesforce.quip.com/gLfGAPtqVzUS#WNbACAiNcVf
        make_nonmatching_import_records(batch_size, factories)  # Per https://salesforce.quip.com/gLfGAPtqVzUS#WNbACAiNcVf


def make_factories(session, classes, Factory):
    """Function that creates factories attached to the right
       database.

       The specification for the factories is defined in
       https://salesforce.quip.com/gLfGAPtqVzUS """
    BaseMeta = SessionBase(session)

    class Payment(Factory):
        class Meta(BaseMeta):
            model = classes.payments

        class Params:
            date_adder_ = Adder(0)  # leading underscore breaks things.
            opportunity = "Opportunity not set"

        id = factory.Sequence(lambda n: n + 1)
        npe01__opportunity__c = factory.LazyAttribute(
            lambda o: o.opportunity.id if o.opportunity else None
        )
        scheduled_date = factory.LazyAttribute(lambda o: o.payment_date)

    class Opportunity(Factory):
        class Meta(BaseMeta):
            model = classes.opportunities
            exclude = "payment"

        class Params:
            with_payment = factory.Trait(
                payment=factory.RelatedFactory(
                    Payment,
                    "opportunity",
                    payment_date=factory.LazyAttribute(
                        lambda o: o.factory_parent.close_date
                    ),
                )
            )
            account = None
            primary_contact = None

        amount = "opportunity amount not set"
        stage_name = "Prospecting"
        id = factory.Sequence(lambda n: n + 1)
        name = factory.LazyAttribute(lambda o: f"{o.factory_parent.name} Donation")
        account_id = factory.LazyAttribute(lambda o: o.account.id if o.account else None)
        primary_contact__c = factory.LazyAttribute(
            lambda o: o.primary_contact.id if o.primary_contact else None
        )
        with_payment = True  # default to having a payment.

    class Account(Factory):
        class Meta(BaseMeta):
            model = classes.accounts

        class Params:
            opportunity_date_adder = "Adder not set"
            opportunity = factory.RelatedFactory(
                Opportunity,
                "account",
                close_date=factory.LazyAttribute(
                    lambda o: START_DATE
                    + timedelta(days=o.factory_parent.opportunity_date_adder(1) - 1)
                ),
            )

        id = factory.Sequence(lambda n: n + 1)

        name = factory.LazyAttribute(lambda o: f"Account {o.id}")
        record_type = "Organization"

    class Contact(Factory):
        class Meta(BaseMeta):
            model = classes.contacts

        class Params:
            opportunity_date_adder = (
                "Adder not set"
            )  # leading underscore breaks things.
            opportunity = factory.RelatedFactory(
                Opportunity,
                "primary_contact",
                close_date=factory.LazyAttribute(
                    lambda o: START_DATE
                    + timedelta(days=o.factory_parent.opportunity_date_adder(1) - 1)
                ),
            )

        id = factory.Sequence(lambda n: n + 1)
        name = factory.Sequence(lambda n: f"Contact {(n + 1)}")

    class DataImport(Factory):
        class Meta(BaseMeta):
            model = classes.DataImport__c

        class Params:
            date_adder = "Adder not set"
            ContactAdder = Adder(0)
            AccountAdder = Adder(0)

        id = factory.Sequence(lambda n: n + 1)
        Donation_Date__c = factory.LazyAttribute(
            lambda o: START_DATE + timedelta(days=o.date_adder(1) - 1)
        )

        Account1_Name__c = factory.LazyAttribute(
            lambda o: f"Account {o.AccountAdder(1)}" if o.Donation_Donor__c == "Account1" else None
        )

        Contact1_Lastname__c = factory.LazyAttribute(
            lambda o: f"Contact {o.ContactAdder(1)}" if o.Donation_Donor__c == "Contact1" else None
        )

        Do_Not_Automatically_Create_Payment__c = "FALSE"

    return Factories(session, vars())


def make_preexisting_records(batch_size, factories):
    """Make the 5 batches of Accounts and 5 of Contacts described here:
        https://salesforce.quip.com/gLfGAPtqVzUS#WNbACAukQAl """
    def create_batch(classname, **kwargs):
        factories.create_batch(classname, batch_size, **kwargs)

    create_batch(
        "Account",
        opportunity____amount=100,
        opportunity____payment____amount=100,
        opportunity____payment____paid=False,
        opportunity_date_adder=Adder(),
    )
    create_batch(
        "Account",
        opportunity____amount=200,
        opportunity____payment____paid=False,
        opportunity_date_adder=Adder(),
        opportunity____payment____amount=200,
    )
    create_batch(
        "Account",
        opportunity____amount=300,
        opportunity____payment____paid=False,
        opportunity_date_adder=Adder(),
        opportunity____payment____amount=50,
    )
    create_batch(
        "Account",
        opportunity____amount=400,
        opportunity____payment____paid=True,
        opportunity_date_adder=Adder(),
        opportunity____payment____amount=50,
    )
    create_batch(
        "Account",
        opportunity____amount=500,
        opportunity_date_adder=Adder(),
        opportunity____with_payment=False,
    )

    create_batch(
        "Contact",
        opportunity____amount=600,
        opportunity____payment____paid=False,
        opportunity_date_adder=Adder(),
        opportunity____payment____amount=600,
    )
    create_batch(
        "Contact",
        opportunity____amount=700,
        opportunity____payment____paid=False,
        opportunity_date_adder=Adder(),
        opportunity____payment____amount=700,
    )
    create_batch(
        "Contact",
        opportunity____amount=800,
        opportunity____payment____paid=False,
        opportunity_date_adder=Adder(),
        opportunity____payment____amount=50,
    )
    create_batch(
        "Contact",
        opportunity____amount=900,
        opportunity____payment____paid=True,
        opportunity_date_adder=Adder(),
        opportunity____payment____amount=50,
    )
    create_batch(
        "Contact",
        opportunity____amount=1000,
        opportunity_date_adder=Adder(),
        opportunity____with_payment=False,
    )


def make_matching_import_records(batch_size, factories):
    """Make the 5-batches of Account-matching and 5-batches of Contact-matching
       DataImport records described here:
       https://salesforce.quip.com/gLfGAPtqVzUS#WNbACAHSe1L
       """
    def create_batch(classname, **kwargs):
        factories.create_batch(classname, batch_size, **kwargs)

    create_batch(
        "DataImport",
        Donation_Amount__c=100,
        Donation_Donor__c="Account1",
        date_adder=Adder(),
    )
    create_batch(
        "DataImport",
        Donation_Amount__c=200,
        Donation_Donor__c="Account1",
        Qualified_Date__c="2020-01-01",
        date_adder=Adder(),
    )
    create_batch(
        "DataImport",
        Donation_Amount__c=50,
        Donation_Donor__c="Account1",
        date_adder=Adder(),
    )
    create_batch(
        "DataImport",
        Donation_Amount__c=400,
        Donation_Donor__c="Account1",
        date_adder=Adder(),
    )
    create_batch(
        "DataImport",
        Donation_Amount__c=500,
        Donation_Donor__c="Account1",
        date_adder=Adder(),
    )
    create_batch(
        "DataImport",
        Donation_Amount__c=600,
        Donation_Donor__c="Contact1",
        date_adder=Adder(),
    )
    create_batch(
        "DataImport",
        Donation_Amount__c=700,
        Donation_Donor__c="Contact1",
        Qualified_Date__c="2020-01-01",
        date_adder=Adder(),
    )
    create_batch(
        "DataImport",
        Donation_Amount__c=50,
        Donation_Donor__c="Contact1",
        date_adder=Adder(),
    )
    create_batch(
        "DataImport",
        Donation_Amount__c=900,
        Donation_Donor__c="Contact1",
        date_adder=Adder(),
    )
    create_batch(
        "DataImport",
        Donation_Amount__c=1000,
        Donation_Donor__c="Contact1",
        date_adder=Adder(),
    )


def make_nonmatching_import_records(batch_size, factories):
    """Make the 4 batches defined here:
       https://salesforce.quip.com/gLfGAPtqVzUS#WNbACAiNcVf"""
    def create_batch(classname, **kwargs):
        factories.create_batch(classname, batch_size, **kwargs)

    newadder = Adder(0)
    create_batch(
        "DataImport",
        Donation_Amount__c=100,
        Donation_Donor__c="Account1",
        Do_Not_Automatically_Create_Payment__c="FALSE",
        Account1_Name__c=factory.LazyAttribute(
            lambda o: f"Account{o.AccountAdder(1)}"
        ),
        AccountAdder=newadder,
        date_adder=Adder(),
    )

    create_batch(
        "DataImport",
        Donation_Amount__c=200,
        Donation_Donor__c="Account1",
        Do_Not_Automatically_Create_Payment__c="TRUE",
        Account1_Name__c=factory.LazyAttribute(
            lambda o: f"Account{o.AccountAdder(1)}"
        ),
        AccountAdder=newadder,
        date_adder=Adder(),
    )

    contactadder = Adder(0)

    create_batch(
        "DataImport",
        Donation_Amount__c=300,
        Donation_Donor__c="Contact1",
        Do_Not_Automatically_Create_Payment__c="FALSE",
        ContactAdder=contactadder,
        Contact1_Lastname__c=factory.LazyAttribute(
            lambda o: f"Contact{o.ContactAdder(1)}"
        ),
        date_adder=Adder(),
    )

    create_batch(
        "DataImport",
        Donation_Amount__c=400,
        Donation_Donor__c="Contact1",
        Do_Not_Automatically_Create_Payment__c="TRUE",
        Contact1_Lastname__c=factory.LazyAttribute(
            lambda o: f"Contact{o.ContactAdder(1)}"
        ),
        ContactAdder=contactadder,
        date_adder=Adder(),
    )
