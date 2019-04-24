from cumulusci.core.utils import ordered_yaml_load
from cumulusci.utils import convert_to_snake_case, log_progress, os_friendly_path
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

MAPPING = "mapping.yml"
DB = "sqlite:///test_data.db"
START_DATE = date(2019, 1, 1)


def generate_data():
    with open(MAPPING, "r") as f:
        mappings = ordered_yaml_load(f)

    session, base = init_db(mappings)
    Account = base.classes.accounts
    Contact = base.classes.contacts
    Opportunity = base.classes.opportunities
    Payment = base.classes.payments

    def make_opportunity(amount, date, paid, payment_amount, **kw):
        opp = Opportunity(amount=amount, stage_name='Closed Won', close_date=date, **kw)
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
        for i in range(start, end + 1):
            parent = model(name=f"{name} {i}")
            session.add(parent)
            session.flush()
            kw = {
                key_field: parent.id,
                'name': f'{name} {i} Donation',
            }
            make_opportunity(amount, date, paid, payment_amount, **kw)
            date = date + timedelta(days=1)

    make_records(
        Account,
        "Account",
        "account_id",
        1,
        500,
        amount=100,
        paid=False,
        payment_amount=100,
    )
    make_records(
        Account,
        "Account",
        "account_id",
        501,
        1000,
        amount=200,
        paid=False,
        payment_amount=200,
    )
    make_records(
        Account,
        "Account",
        "account_id",
        1001,
        1500,
        amount=300,
        paid=False,
        payment_amount=50,
    )
    make_records(
        Account,
        "Account",
        "account_id",
        1501,
        2000,
        amount=400,
        paid=True,
        payment_amount=50,
    )
    make_records(
        Account,
        "Account",
        "account_id",
        2001,
        2500,
        amount=500,
        paid=False,
        payment_amount=None,
    )

    make_records(
        Contact,
        "Contact",
        "primary_contact__c",
        1,
        500,
        amount=600,
        paid=False,
        payment_amount=600,
    )
    make_records(
        Contact,
        "Contact",
        "primary_contact__c",
        501,
        1000,
        amount=700,
        paid=False,
        payment_amount=700,
    )
    make_records(
        Contact,
        "Contact",
        "primary_contact__c",
        1001,
        1500,
        amount=800,
        paid=False,
        payment_amount=50,
    )
    make_records(
        Contact,
        "Contact",
        "primary_contact__c",
        1501,
        2000,
        amount=900,
        paid=True,
        payment_amount=50,
    )
    make_records(
        Contact,
        "Contact",
        "primary_contact__c",
        2001,
        2500,
        amount=1000,
        paid=False,
        payment_amount=None,
    )

    session.commit()

# Note: code below here is taken from cumulusci.tasks.bulkdata.QueryData,
# and really we should refactor it there to be more reusable.

def init_db(mappings):
    models = {}
    engine = create_engine(DB)
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


if __name__ == "__main__":
    generate_data()
