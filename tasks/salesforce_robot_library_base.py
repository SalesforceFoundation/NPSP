import logging
import os
import pprint

from cumulusci.core.config import TaskConfig
from robot.libraries.BuiltIn import BuiltIn
from cumulusci.tasks.apex.anon import AnonymousApexTask

from cumulusci.tasks.apex.batch import BatchApexWait


class SalesforceRobotLibraryBase(object):
    logger = logging.getLogger("robot_debug")
    logger.setLevel("DEBUG")

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

    def _batch_apex_wait(self, class_name):
        return self._run_subtask(BatchApexWait, class_name=class_name)

    def _run_apex(self, code):
        return self._run_subtask(AnonymousApexTask, apex=code)

    def _python_display(self, title, *value, say=False):
        """Helper function for printing things to stdout for debugging.
           Not intended at all to be the final answer to debug logging in
           Robot tests and keywords, but useful for now.

           Also exposed as a keyword by Data.py/Data.robot """
        if isinstance(value, str) or not value:
            pass
        elif any(isinstance(value, t) for t in [list, dict, tuple]):
            value = pprint.pformat(value)
        else:
            value = repr(value)
        if value:
            print("%s: %s" % (title, value))
        else:
            print(title)
        if say:
            value = value.replace("'", "")
            value = value.replace('"', "")
            value = value.replace('`', "")
            os.system(f'say {title}')
