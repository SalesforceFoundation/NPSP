import tempfile
import shutil
import os
import math
from cumulusci.tasks.salesforce import BaseSalesforceApiTask
from cumulusci.tasks.bulkdata import LoadData
from cumulusci.core.utils import ordered_yaml_load
from cumulusci.utils import convert_to_snake_case, log_progress, os_friendly_path
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
STEP_HACK = 100


class GenerateBDIData(BaseSalesforceApiTask):
    def _run_task(self):
        self.tempdir = tempfile.mkdtemp()
        try:
            sqlite_path = os.path.join(self.tempdir, "generated_data.db")
            url = "sqlite:///" + sqlite_path
            batch_size = math.floor(self.options["num_records"] / 5)
            generate_data(url, self.options["mapping"], batch_size)
            subtask_config = TaskConfig(
                {"options": {"database_url": url, "mapping": self.options["mapping"]}}
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
        finally:
            shutil.rmtree(self.tempdir)


def generate_data(db_url, mapping_file_path, batch_size):
    with open(mapping_file_path, "r") as f:
        mappings = ordered_yaml_load(f)

    session, base = init_db(db_url, mappings)
    Account = base.classes.accounts
    Contact = base.classes.contacts
    Opportunity = base.classes.opportunities
    Payment = base.classes.payments

    def make_opportunity(amount, date, paid, payment_amount, **kw):
        opp = Opportunity(
            amount=amount, stage_name="Prospecting", close_date=date, **kw
        )
        session.add(opp)
        session.flush()
        if payment_amount:
            payment = Payment(
                npe01__opportunity__c=opp.id,
                amount=payment_amount,
                payment_date=date,
                paid=paid,
            )
            session.add(payment)

    def make_records(model, name, key_field, start, end, amount, paid, payment_amount):
        date = START_DATE
        for i in range(start, end + 1, STEP_HACK):
            parent = model(name=f"{name} {i}")
            if model is Account:
                parent.record_type = "Organization"
            session.add(parent)
            session.flush()
            kw = {key_field: parent.id, "name": f"{name} {i} Donation"}
            make_opportunity(amount, date, paid, payment_amount, **kw)
            date = date + timedelta(days=1)

    class Adder:
        x = 0

        def __call__(self, value):
            self.x += value
            return self.x

    account_adder = Adder()

    make_records(
        Account,
        "Account",
        "account_id",
        account_adder(1),
        account_adder(batch_size),
        amount=100,
        paid=False,
        payment_amount=100,
    )
    make_records(
        Account,
        "Account",
        "account_id",
        account_adder(1),
        account_adder(batch_size),
        amount=200,
        paid=False,
        payment_amount=200,
    )
    make_records(
        Account,
        "Account",
        "account_id",
        account_adder(1),
        account_adder(batch_size),
        amount=300,
        paid=False,
        payment_amount=50,
    )
    make_records(
        Account,
        "Account",
        "account_id",
        account_adder(1),
        account_adder(batch_size),
        amount=400,
        paid=True,
        payment_amount=50,
    )
    make_records(
        Account,
        "Account",
        "account_id",
        account_adder(1),
        account_adder(batch_size),
        amount=500,
        paid=False,
        payment_amount=None,
    )

    contacts_adder = Adder()
    make_records(
        Contact,
        "Contact",
        "primary_contact__c",
        contacts_adder(1),
        contacts_adder(batch_size),
        amount=600,
        paid=False,
        payment_amount=600,
    )
    make_records(
        Contact,
        "Contact",
        "primary_contact__c",
        contacts_adder(1),
        contacts_adder(batch_size),
        amount=700,
        paid=False,
        payment_amount=700,
    )
    make_records(
        Contact,
        "Contact",
        "primary_contact__c",
        contacts_adder(1),
        contacts_adder(batch_size),
        amount=800,
        paid=False,
        payment_amount=50,
    )
    make_records(
        Contact,
        "Contact",
        "primary_contact__c",
        contacts_adder(1),
        contacts_adder(batch_size),
        amount=900,
        paid=True,
        payment_amount=50,
    )
    make_records(
        Contact,
        "Contact",
        "primary_contact__c",
        contacts_adder(1),
        contacts_adder(batch_size),
        amount=1000,
        paid=False,
        payment_amount=None,
    )

    generate_bdi_denormalized_table(session, (2500 // STEP_HACK) // 2)
    session.commit()


def generate_bdi_denormalized_table(session, limit):
    session.execute(
        """
    INSERT INTO npsp__DataImport__c
        SELECT
            payments.Id as Id, -- unique id
            accounts.name, -- account_name -> npe01__Account1_Name__c
            contacts.name, -- contact1_lastname -> npe01__Contact1_Lastname__c
            opportunities.name, -- donation_name ->  npe01__Donation_Name__c
            opportunities.stage_name, -- donation_stage -> npe01__Donation_Stage__c
            opportunities.amount, -- donation_amount -> npe01__Donation_Amount__c
            opportunities.close_date -- donation_date -> npe01__Donation_Date__c
        -- disabled   FALSE -- do_not_automatically_create_payment -> npe01__Do_Not_Automatically_Create_Payment__c
        FROM payments
        left join opportunities ON npe01__opportunity__c=opportunities.Id
        left join contacts on primary_contact__c=contacts.Id
        left join accounts on opportunities.account_id=accounts.Id
        WHERE payments.Id %% 2  -- only half of the records
        LIMIT %s;
        """
        % limit
    )


# Note: code below here is taken from cumulusci.tasks.bulkdata.QueryData,
# and really we should refactor it there to be more reusable.


def init_db(db_url, mappings):
    models = {}
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
    model_name = "{}Model".format(mapping["table"])
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
