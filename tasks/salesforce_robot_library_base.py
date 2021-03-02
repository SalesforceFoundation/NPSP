import logging
import os
import pprint

from robot.libraries.BuiltIn import BuiltIn

cumulusci_library = "cumulusci.robotframework.CumulusCI"
salesforce_library = "cumulusci.robotframework.Salesforce"


class SalesforceRobotLibraryBase(object):
    logger = logging.getLogger("robot_debug")
    logger.setLevel("DEBUG")

    @property
    def builtin(self):
        return BuiltIn()

    @property
    def cumulusci(self):
        return self.builtin.get_library_instance(cumulusci_library)

    @property
    def salesforce(self):
        return self.builtin.get_library_instance(salesforce_library)

    def _run_subtask(self, taskname, **options):
        return self.cumulusci.run_task(taskname, **options)

    def _batch_apex_wait(self, class_name):
        return self._run_subtask("batch_apex_wait", class_name=class_name)

    def _run_apex(self, code):
        return self._run_subtask("execute_anon", apex=code)

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
