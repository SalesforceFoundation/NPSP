import os
import math
from cumulusci.tasks.salesforce import BaseSalesforceApiTask
from cumulusci.tasks.bulkdata import LoadData
from cumulusci.core.utils import ordered_yaml_load
from cumulusci.utils import convert_to_snake_case, temporary_dir
from cumulusci.core.config import TaskConfig
from sqlalchemy import create_engine
from sqlalchemy import Column
from sqlalchemy import MetaData
from sqlalchemy import Integer
from sqlalchemy import Table
from sqlalchemy import Unicode
from sqlalchemy.ext.automap import automap_base
from sqlalchemy.orm import create_session


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
        "mapping": {"description": "A mapping YAML file to use", "required": True},
        "database_url": {"description": "A path to put a copy of the sqlite database (for debugging)", "required": False},
    }

    def _run_task(self):
        mapping_file = os.path.abspath(self.options["mapping"])
        database_url = self.options.get("database_url")
        if not database_url:
            sqlite_path = "generated_data.db"
            self.logger.info("No database URL: creating sqlite file {sqlite_path}")
            database_url = "sqlite:///" + sqlite_path

        num_records = int(self.options["num_records"])
        self._generate_data(database_url, mapping_file, num_records)

    def _generate_data(self, db_url, mapping_file_path, num_records):
        """Generate all of the data"""
        with open(mapping_file_path, "r") as f:
            mappings = ordered_yaml_load(f)

        session, engine, base = self.init_db(db_url, mappings)
        self.generate_data(session, engine, base, num_records)
        session.commit()

    def init_db(self, db_url, mappings):
        engine = create_engine(db_url)
        metadata = MetaData()
        metadata.bind = engine
        for mapping in mappings.values():
            create_table(mapping, metadata)
        metadata.create_all()
        base = automap_base(bind=engine, metadata=metadata)
        base.prepare(engine, reflect=True)
        session = create_session(bind=engine, autocommit=False)
        return session, engine, base

    def generate_data(self, session, engine, base):
        raise NotImplementedError("generate_data method")


# Note: code below here is taken from cumulusci.tasks.bulkdata.QueryData,
# and really we should refactor it there to be more reusable.


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
