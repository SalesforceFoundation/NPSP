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

START_DATE = date(2019, 1, 1)


class GenerateBDIData(BaseSalesforceApiTask):

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
        num_records = int(self.options["num_records"])
        debug_db_path = self.options["debug_db_path"]
        with temporary_dir() as tempdir:
            if(debug_db_path):
                sqlite_path = debug_db_path
            else:
                sqlite_path = os.path.join(tempdir, "generated_data.db")
            url = "sqlite:///" + sqlite_path
            batch_size = math.floor(num_records / 10)
            self.generate_data(url, mapping_file, batch_size)
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

    def generate_data(self, db_url, mapping_file_path, batch_size):
        """Generate all of the data"""
        with open(mapping_file_path, "r") as f:
            mappings = ordered_yaml_load(f)

        self.session, base = init_db(db_url, mappings)
        self.make_all_records(batch_size, base)
        self.generate_bdi_denormalized_table(2)
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
            )
            self.session.add(payment)

    def make_records(
        self, model, name, key_field, start, end, amount, paid, payment_amount
    ):
        """Make a batch of records according to a specification"""
        date = START_DATE
        for i in range(start + 1, end + 1):
            parent = model(name=name + " " + str(i))
            if model is self.Account:
                parent.record_type = "Organization"
            self.session.add(parent)
            self.session.flush()
            kw = {key_field: parent.id, "name": f"{name} {i} Donation"}
            self.make_opportunity(amount, date, paid, payment_amount, **kw)
            date = date + timedelta(days=1)

    def make_all_records(self, batch_size, base):
        """Make all of the records"""
        class Adder:
            x = 0

            def __call__(self, value):
                self.x += value
                return self.x

        Account = self.Account = base.classes.accounts
        Contact = self.Contact = base.classes.contacts
        self.Opportunity = base.classes.opportunities
        self.Payment = base.classes.payments
        account_adder = Adder()

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

        contacts_adder = Adder()
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

    def generate_bdi_denormalized_table(self, fraction):
        """BDI has a denormalized import table called npsp__DataImport__c.
           Generate that table using a mix of matching and umatching data.
           
           Fraction is slightly non-intuitive. It's the proportion of existing
           records to match in the BDI table. So 1 means match 1 to 1.
           2 means match half. 3 means match a third. The bigger the number,
           the smaller the size of the BDI table.
           """
        self.generate_matching_records(fraction)
        self.generate_unmatched_records(fraction)

    def generate_matching_records(self, fraction):
        """Generate records that match what's already "in" the org by
           copying the records from the tables that will be populated in the
           org. """
        self.session.execute(
            """
        INSERT INTO npsp__DataImport__c
            SELECT
                Opportunities.Id as Id, -- unique id
            accounts.name, -- account_name -> npe01__Account1_Name__c
            contacts.name, -- contact1_lastname -> npe01__Contact1_Lastname__c
            opportunities.name, -- donation_name ->  npe01__Donation_Name__c
            opportunities.stage_name, -- donation_stage -> npe01__Donation_Stage__c
            opportunities.amount, -- donation_amount -> npe01__Donation_Amount__c
            opportunities.close_date -- donation_date -> npe01__Donation_Date__c
        -- disabled   FALSE -- do_not_automatically_create_payment -> npe01__Do_Not_Automatically_Create_Payment__c
        FROM Opportunities
            LEFT JOIN contacts on primary_contact__c=contacts.Id
            LEFT JOIN accounts on opportunities.account_id=accounts.Id
        WHERE Opportunities.Id %% %(fraction)s = 0 -- only half (or other portion) of the records
            """
            % {"fraction": fraction}
        )

    def generate_unmatched_records(self, fraction):
        """Make a randomized record for every real record in the npsp__DataImport__c
           table so that we test the process of failing to match records."""
        self.session.execute(
            """
        INSERT INTO npsp__DataImport__c
            SELECT
                Id + (SELECT MAX(Id) from npsp__DataImport__c), -- unique id
                lower(hex(randomblob(16))), -- account_name -> npe01__Account1_Name__c
                lower(hex(randomblob(16))), -- contact1_lastname -> npe01__Contact1_Lastname__c
                lower(hex(randomblob(16))), -- donation_name ->  npe01__Donation_Name__c
                donation_stage, -- donation_stage -> npe01__Donation_Stage__c
                donation_amount, -- donation_amount -> npe01__Donation_Amount__c
                donation_date -- donation_date -> npe01__Donation_Date__c
        -- disabled   FALSE -- do_not_automatically_create_payment -> npe01__Do_Not_Automatically_Create_Payment__c
        FROM npsp__DataImport__c
            """
        )


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
