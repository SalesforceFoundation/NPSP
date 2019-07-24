import os
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
from sqlalchemy import orm
from sqlalchemy.sql.expression import func
from .generate_bdi_data import BatchDataTask, init_db

from .bdi_record_factory import make_records


class DataFactoryTask(BatchDataTask):
    def _generate_data(self, db_url, mapping_file_path, num_records):
        """Generate all of the data"""
        with open(mapping_file_path, "r") as f:
            mappings = ordered_yaml_load(f)

        session, base = init_db(db_url, mappings)
        make_records(num_records, session, base)
        session.flush()
        session.commit()
