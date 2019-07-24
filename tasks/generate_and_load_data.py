import os
from cumulusci.tasks.salesforce import BaseSalesforceApiTask
from cumulusci.tasks.bulkdata import LoadData
from cumulusci.core.utils import ordered_yaml_load
from cumulusci.utils import convert_to_snake_case, temporary_dir
from cumulusci.core.config import TaskConfig
from cumulusci.core.utils import import_global


class GenerateAndLoadData(BaseSalesforceApiTask):
    task_docs = """
    Use the `num_records` option to specify how many records to generate.
    Use the `mappings` option to specify a mapping file.
    """

    task_options = {
        "num_records": {
            "description": "How many records to generate: total number of opportunities.",
            "required": True},
        "mapping": {"description": "A mapping YAML file to use",
                         "required": True},
        "data_generation_task": {"description": "Fully qualified class path of a task to generate the data.",
                         "required": True},
        "database_url": {"description": "A URL to store the database (defaults to a transient SQLite file)",
                         "required": ""},
    }

    def _run_task(self):
        mapping_file = os.path.abspath(self.options["mapping"])
        assert os.path.exists(mapping_file), f"{mapping_file} cannot be found."
        database_url = self.options.get("database_url")
        with temporary_dir() as tempdir:
            if not database_url:
                sqlite_path = os.path.join(tempdir, "generated_data.db")
                database_url = f"sqlite:///" + sqlite_path

            subtask_options = {**self.options, "mapping": mapping_file, "database_url": database_url}
            class_path = self.options["data_generation_task"]

            task_class = import_global(class_path)
            task_config = TaskConfig({"options": subtask_options})
            data_gen_task = task_class(self.project_config, task_config, org_config=self.org_config)
            data_gen_task()

            subtask_config = TaskConfig({"options": subtask_options})
            subtask = LoadData(
                project_config=self.project_config,
                task_config=subtask_config,
                org_config=self.org_config,
                flow=self.flow,
                name=self.name,
                stepnum=self.stepnum,
            )
            subtask()
