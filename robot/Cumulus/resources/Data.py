from cumulusci.core.config import TaskConfig
from robot.libraries.BuiltIn import BuiltIn

from tasks.npsp_delete import DeleteData


class SFRobotBase(object):
    @property
    def builtin(self):
        return BuiltIn()

    @property
    def cumulusci(self):
        return self.builtin.get_library_instance("cumulusci.robotframework.CumulusCI")

    @property
    def salesforce(self):
        return self.builtin.get_library_instance("cumulusci.robotframework.Salesforce")

    def _run_subtask(self, taskclass, **options):
        subtask_config = TaskConfig({"options": options})
        return self.cumulusci._run_task(taskclass, subtask_config)


class Data(SFRobotBase):
    def delete(self, objects, *, where=None, hardDelete=False):
        self._run_subtask(DeleteData, objects=objects, where=where, hardDelete=hardDelete)
