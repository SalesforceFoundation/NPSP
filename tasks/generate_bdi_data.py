import os
import math
from cumulusci.tasks.salesforce import BaseSalesforceApiTask
from cumulusci.tasks.bulkdata import LoadData
from cumulusci.core.utils import ordered_yaml_load
from cumulusci.utils import convert_to_snake_case, temporary_dir
from cumulusci.core.config import TaskConfig
from datetime import date
from datetime import timedelta
from sqlalchemy import create_engine
from sqlalchemy import Column
from sqlalchemy import MetaData
from sqlalchemy import Integer
from sqlalchemy import Table
from sqlalchemy import Unicode
from sqlalchemy.ext.automap import automap_base
from sqlalchemy.orm import create_session
from sqlalchemy.sql.expression import func


START_DATE = date(2019, 1, 1)


class BatchDataTask(BaseSalesforceApiTask):
    task_docs = """
    Use the `num_records` option to specify how many records to generate.
    Use the `mappings` option to specify a mapping file.
    """

    task_options = {
        "num_records": {
            "description": "How many records to generate: total number of opportunities.",
            "required": True,
        },
        "mapping_yaml": {"description": "A mapping YAML file to use", "required": True},
        "debug_db_path": {"description": "A path to put a copy of the sqlite database (for debugging)", "required": False},
    }

    def _run_task(self):
        mapping_file = os.path.abspath(self.options["mapping_yaml"])
        debug_db_path = self.options.get("debug_db_path")
        with temporary_dir() as tempdir:
            if(debug_db_path):
                sqlite_path = debug_db_path
            else:
                sqlite_path = os.path.join(tempdir, "generated_data.db")
            url = "sqlite:///" + sqlite_path
            self._generate_data(url, mapping_file)
            subtask_config = TaskConfig(
                {"options": {"database_url": url, "mapping": mapping_file}}
            )
            subtask = LoadData(
                project_config=self.project_config,
                task_config=subtask_config,
                org_config=self.org_config,
                flow=self.flow,
                name=self.name,
                stepnum=self.stepnum,
            )
            subtask()

    def _generate_data(self, db_url, mapping_file_path):
        """Generate all of the data"""
        with open(mapping_file_path, "r") as f:
            mappings = ordered_yaml_load(f)

        session, base = init_db(db_url, mappings)
        self.generate_data(session, base)
        self.session.commit()

    def generate_data(self, session, base):
        raise NotImplementedError("generate_data method")


class Adder:
    def __init__(self, x=0):
        self.x = x

    def __call__(self, value):
        self.x += value
        return int(self.x)


class GenerateBDIData(BatchDataTask):
    def generate_data(self, session, base):
        self.session = session
        self.base = base
        num_records = int(self.options["num_records"])
        batch_size = math.floor(num_records / 10)
        self.make_all_records(batch_size)
        self.generate_bdi_denormalized_table(num_records)
        self.session.commit()

    def make_opportunity(self, amount, date, paid, payment_amount, **kw):
        """Make a specific opportunity and matching payment records"""
        opp = self.Opportunity(
            amount=amount, stage_name="Prospecting", close_date=date, **kw
        )
        self.session.add(opp)
        self.session.flush()
        if payment_amount:
            payment = self.Payment(
                npe01__opportunity__c=opp.id,
                amount=payment_amount,
                payment_date=date,
                paid=paid,
                scheduled_date=date
            )
            self.session.add(payment)

    def make_records(
        self, model, name, key_field, start, end, amount, paid, payment_amount
    ):
        """Make a batch of records according to a specification"""
        date = START_DATE
        for i in range(start, end):
            parent = model(name=name + " " + str(i))
            if model is self.Account:
                parent.record_type = "Organization"
            self.session.add(parent)
            self.session.flush()
            kw = {key_field: parent.id, "name": "%s %d Donation" % (name, i)}
            self.make_opportunity(amount, date, paid, payment_amount, **kw)
            date = date + timedelta(days=1)

    def make_all_records(self, batch_size):
        """Make all of the records"""
        base = self.base

        Account = self.Account = base.classes.accounts
        Contact = self.Contact = base.classes.contacts
        self.Opportunity = base.classes.opportunities
        self.Payment = base.classes.payments
        account_adder = Adder(1)

        self.make_records(
            Account,
            "Account",
            "account_id",
            account_adder(0),
            account_adder(batch_size),
            amount=100,
            paid=False,
            payment_amount=100,
        )
        self.make_records(
            Account,
            "Account",
            "account_id",
            account_adder(0),
            account_adder(batch_size),
            amount=200,
            paid=False,
            payment_amount=200,
        )
        self.make_records(
            Account,
            "Account",
            "account_id",
            account_adder(0),
            account_adder(batch_size),
            amount=300,
            paid=False,
            payment_amount=50,
        )
        self.make_records(
            Account,
            "Account",
            "account_id",
            account_adder(0),
            account_adder(batch_size),
            amount=400,
            paid=True,
            payment_amount=50,
        )
        self.make_records(
            Account,
            "Account",
            "account_id",
            account_adder(0),
            account_adder(batch_size),
            amount=500,
            paid=False,
            payment_amount=None,
        )

        contacts_adder = Adder(1)
        self.make_records(
            Contact,
            "Contact",
            "primary_contact__c",
            contacts_adder(0),
            contacts_adder(batch_size),
            amount=600,
            paid=False,
            payment_amount=600,
        )
        self.make_records(
            Contact,
            "Contact",
            "primary_contact__c",
            contacts_adder(0),
            contacts_adder(batch_size),
            amount=700,
            paid=False,
            payment_amount=700,
        )
        self.make_records(
            Contact,
            "Contact",
            "primary_contact__c",
            contacts_adder(0),
            contacts_adder(batch_size),
            amount=800,
            paid=False,
            payment_amount=50,
        )
        self.make_records(
            Contact,
            "Contact",
            "primary_contact__c",
            contacts_adder(0),
            contacts_adder(batch_size),
            amount=900,
            paid=True,
            payment_amount=50,
        )
        self.make_records(
            Contact,
            "Contact",
            "primary_contact__c",
            contacts_adder(0),
            contacts_adder(batch_size),
            amount=1000,
            paid=False,
            payment_amount=None,
        )

    def generate_bdi_denormalized_table(self, num_records):
        """BDI has a denormalized import table called npsp__DataImport__c.
           Generate that table using a mix of matching and umatching data.
           """
        self.generate_matching_records(num_records)

    def generate_matching_records(self, num_records):
        """Generate records that match what's already "in" the org by
           copying the records from the tables that will be populated in the
           org. """
        batch_size = math.floor(num_records / 10)

        def cleanup_value(value, context):
            if type(value)==str:
                return value % context
            elif type(value)==bool:
                return str(value).upper()
            else:
                return value

        def make_records_import_table(adder, **kwargs):
            autoincrement_date = START_DATE
            for i in range(adder(0), adder(batch_size)):
                replaceables = {'i': i}
                fields = {key: cleanup_value(value, replaceables) for key, value in kwargs.items()}
                fields['npsp__Donation_Date__c'] = autoincrement_date
                fields.setdefault('npsp__Do_Not_Automatically_Create_Payment__c', "FALSE")
                record = self.base.classes.npsp__DataImport__c(**fields)
                autoincrement_date = autoincrement_date + timedelta(days=1)
                self.session.add(record)

        account_adder = Adder(1)

        make_records_import_table(account_adder,
            npsp__Account1_Name__c = "Account %(i)d",
            npsp__Donation_Amount__c = 100,
            npsp__Donation_Donor__c = "Account1")

        make_records_import_table(account_adder,
            npsp__Account1_Name__c = "Account %(i)d",
            npsp__Donation_Amount__c = 200,
            npsp__Donation_Donor__c = "Account1",
            npsp__Qualified_Date__c = '2020-01-01')

        make_records_import_table(account_adder,
            npsp__Account1_Name__c = "Account %(i)d",
            npsp__Donation_Amount__c = 50,
            npsp__Donation_Donor__c = "Account1")

        make_records_import_table(account_adder,
            npsp__Account1_Name__c = "Account %(i)d",
            npsp__Donation_Amount__c = 400,
            npsp__Donation_Donor__c = "Account1")

        make_records_import_table(account_adder,
            npsp__Account1_Name__c = "Account %(i)d",
            npsp__Donation_Amount__c = 500,
            npsp__Donation_Donor__c = "Account1")

        contact_adder = Adder(1)

        make_records_import_table(contact_adder,
            npsp__Contact1_Lastname__c = "Contact %(i)d",
            npsp__Donation_Amount__c = 600,
            npsp__Donation_Donor__c = "Contact1")

        make_records_import_table(contact_adder,
            npsp__Contact1_Lastname__c = "Contact %(i)d",
            npsp__Donation_Amount__c = 700,
            npsp__Donation_Donor__c = "Contact1",
            npsp__Qualified_Date__c = '2020-01-01')

        make_records_import_table(contact_adder,
            npsp__Contact1_Lastname__c = "Contact %(i)d",
            npsp__Donation_Amount__c = 50,
            npsp__Donation_Donor__c = "Contact1")

        make_records_import_table(contact_adder,
            npsp__Contact1_Lastname__c = "Contact %(i)d",
            npsp__Donation_Amount__c = 900,
            npsp__Donation_Donor__c = "Contact1")

        make_records_import_table(contact_adder,
            npsp__Contact1_Lastname__c = "Contact %(i)d",
            npsp__Donation_Amount__c = 1000,
            npsp__Donation_Donor__c = "Contact1")

        batch_size = math.floor(num_records / 4)
        account_adder = Adder(1)

        make_records_import_table(account_adder,
            npsp__Account1_Name__c = "Account%(i)d",
            npsp__Donation_Amount__c = 100,
            npsp__Donation_Donor__c = "Account1",
            npsp__Do_Not_Automatically_Create_Payment__c = False
            )

        make_records_import_table(account_adder,
            npsp__Account1_Name__c = "Account%(i)d",
            npsp__Donation_Amount__c = 200,
            npsp__Donation_Donor__c = "Account1",
            npsp__Do_Not_Automatically_Create_Payment__c = True
            )
        contact_adder = Adder(1)

        make_records_import_table(contact_adder,
            npsp__Contact1_Lastname__c = "Contact%(i)d",
            npsp__Donation_Amount__c = 300,
            npsp__Donation_Donor__c = "Contact1",
            npsp__Do_Not_Automatically_Create_Payment__c = False
            )

        make_records_import_table(contact_adder,
            npsp__Contact1_Lastname__c = "Contact%(i)d",
            npsp__Donation_Amount__c = 400,
            npsp__Donation_Donor__c = "Contact1",
            npsp__Do_Not_Automatically_Create_Payment__c = True
            )

        self.session.flush()


# Note: code below here is taken from cumulusci.tasks.bulkdata.QueryData,
# and really we should refactor it there to be more reusable.


def init_db(db_url, mappings):
    engine = create_engine(db_url)
    metadata = MetaData()
    metadata.bind = engine
    for mapping in mappings.values():
        create_table(mapping, metadata)
    metadata.create_all()
    base = automap_base(bind=engine, metadata=metadata)
    base.prepare(engine, reflect=True)
    session = create_session(bind=engine, autocommit=False)
    return session, base


def create_table(mapping, metadata):
    table_kwargs = {}

    # Provide support for legacy mappings which used the OID as the pk but
    # default to using an autoincrementing int pk and a separate sf_id column
    fields = []
    mapping["oid_as_pk"] = bool(mapping.get("fields", {}).get("Id"))
    if mapping["oid_as_pk"]:
        id_column = mapping["fields"]["Id"]
        fields.append(Column(id_column, Unicode(255), primary_key=True))
    else:
        fields.append(Column("id", Integer(), primary_key=True, autoincrement=True))
    for field in fields_for_mapping(mapping):
        if mapping["oid_as_pk"] and field["sf"] == "Id":
            continue
        fields.append(Column(field["db"], Unicode(255)))
    if "record_type" in mapping:
        fields.append(Column("record_type", Unicode(255)))
    t = Table(mapping["table"], metadata, *fields, **table_kwargs)
    if t.exists():
        raise Exception("Table already exists: {}".format(mapping["table"]))


def fields_for_mapping(mapping):
    fields = []
    for sf_field, db_field in mapping.get("fields", {}).items():
        fields.append({"sf": sf_field, "db": db_field})
    for sf_field, lookup in mapping.get("lookups", {}).items():
        fields.append({"sf": sf_field, "db": get_lookup_key_field(lookup, sf_field)})
    return fields


def get_lookup_key_field(lookup, sf_field):
    return lookup.get("key_field", convert_to_snake_case(sf_field))
