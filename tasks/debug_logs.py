import datetime
import os
import csv

from cumulusci.tasks.salesforce import BaseSalesforceApiTask


class TurnOnDebugLogs(BaseSalesforceApiTask):
    task_docs = """
    Turn on debugging information in Salesforce
    """

    debug_level_id = None  # Class variable

    def _run_task(self):
        """Create a TraceFlag for a given user."""
        self._delete_debug_levels()
        self._delete_trace_flags()
        self.logger.info("Creating DebugLevel object")
        DebugLevel = self._get_tooling_object("DebugLevel")
        result = DebugLevel.create(
            {
                "ApexCode": "Info",
                "ApexProfiling": "Debug",
                "Callout": "Info",
                "Database": "Info",
                "DeveloperName": "CumulusCI",
                "MasterLabel": "CumulusCI",
                "System": "Info",
                "Validation": "Info",
                "Visualforce": "Info",
                "Workflow": "Info",
            }
        )
        if TurnOnDebugLogs.debug_level_id:
            self.logger.info(
                "Debug logs are already turned on ({TurnOnDebugLogs.debug_level_id})"
            )
            return
        TurnOnDebugLogs.debug_level_id = result["id"]
        self.logger.info("Setting up trace flag to capture debug logs")
        # New TraceFlag expires 12 hours from now
        expiration_date = datetime.datetime.utcnow() + datetime.timedelta(
            seconds=60 * 60 * 12
        )
        TraceFlag = self._get_tooling_object("TraceFlag")
        result = TraceFlag.create(
            {
                "DebugLevelId": result["id"],
                "ExpirationDate": expiration_date.isoformat(),
                "LogType": "USER_DEBUG",
                "TracedEntityId": self.org_config.user_id,
            }
        )
        self.logger.info("Created TraceFlag for user")

    def _delete_trace_flags(self):
        """
        Delete existing DebugLevel objects.
        This will automatically delete associated TraceFlags as well.
        """
        self.logger.info("Deleting existing TraceFlag objects")
        result = self.tooling.query(
            "Select Id from TraceFlag Where TracedEntityId = '{}'".format(
                self.org_config.user_id
            )
        )
        if result["totalSize"]:
            TraceFlag = self._get_tooling_object("TraceFlag")
            for record in result["records"]:
                TraceFlag.delete(str(record["Id"]))

    def _delete_debug_levels(self):
        """
        Delete existing DebugLevel objects.
        This will automatically delete associated TraceFlags as well.
        """
        self.logger.info("Deleting existing DebugLevel objects")
        result = self.tooling.query("Select Id from DebugLevel")
        if result["totalSize"]:
            DebugLevel = self._get_tooling_object("DebugLevel")
            for record in result["records"]:
                DebugLevel.delete(str(record["Id"]))


# Based on https://github.com/SFDO-Tooling/CumulusCI/blob/225c6fcc6d625330abebe9efb087bba84f2daaa5/cumulusci/tasks/salesforce.py#L1511
class DownloadDebugLogs(BaseSalesforceApiTask):
    task_docs = """
    Download debug logs from Salesforce.
    """

    task_options = {
        "debug_log_dir": {"description": "Where to put the logs", "required": True}
    }

    def _run_task(self):
        result = self.tooling.query_all(
            "SELECT Id, Application, "
            + "DurationMilliseconds, Location, LogLength, LogUserId, "
            + "Operation, Request, StartTime, Status "
            + "from ApexLog"
        )
        debug_log_dir = self.options.get("debug_log_dir")
        if not os.path.exists(debug_log_dir):
            os.makedirs(debug_log_dir)
        filename = "%s/%s.csv" % (
            debug_log_dir,
            str(datetime.datetime.utcnow()).replace(" ", "-"),
        )

        with open(filename, "w", newline="") as f:
            # the original code had a one-class-per-file layout
            # which could be restored if helpful. See URL above.
            fieldnames = [
                "Id",
                "Application",
                "DurationMilliseconds",
                "Location",
                "LogLength",
                "LogUserId",
                "Operation",
                "Request",
                "StartTime",
                "Status",
            ]
            writer = csv.DictWriter(f, fieldnames, extrasaction="ignore")
            writer.writeheader()
            for log in result["records"]:
                writer.writerow(log)
                log_file = os.path.join(debug_log_dir, log['Id'] + '.log')
                try:
                    self.write_logfile(log_file, log['Id'])
                except Exception as e:
                    self.logger.info(f"Cannot write {log_file} because {e}")

        self.logger.info("Created: " + filename)

        if TurnOnDebugLogs.debug_level_id:
            DebugLevel = self._get_tooling_object("DebugLevel")
            DebugLevel.delete(str(TurnOnDebugLogs.debug_level_id))
            TurnOnDebugLogs.debug_level_id = None

    def write_logfile(self, log_file, logid):
        body_url = '{}sobjects/ApexLog/{}/Body'.format(
            self.tooling.base_url, logid)
        response = self.tooling.request.get(body_url,
                                            headers=self.tooling.headers)

        with open(log_file, mode='w', encoding='utf-8') as f:
            f.write(self._decode_to_unicode(response.content))
            self.logger.info(f"Created {log_file}")


    # I don't really understand the purpose of this code but I'm copying it
    # from the original version of this code
    def _decode_to_unicode(self, content):
        if content:
            try:
                # Try to decode ISO-8859-1 to unicode
                return content.decode('ISO-8859-1')
            except UnicodeEncodeError:
                # Assume content is unicode already
                return content
