from cumulusci.tasks.bulkdata import DeleteData
from tasks.salesforce_robot_library_base import SalesforceRobotLibraryBase


class Data(SalesforceRobotLibraryBase):
    def bulk_delete(self, objects, *, where=None, hardDelete=False):
        self._run_subtask(DeleteData, objects=objects, where=where, hardDelete=hardDelete)
