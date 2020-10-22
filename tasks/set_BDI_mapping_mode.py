from cumulusci.tasks.apex.anon import AnonymousApexTask
from cumulusci.core.exceptions import TaskOptionsError
import time


class SetBDIMappingMode(AnonymousApexTask):
    """Change the mapping mode for NPSP BGE/BDI."""
    task_docs = """
    Use the 'mode' argument to specify either 'Help Text' or 'Data Import Field Mapping'
    """

    help_text_apex = """
        BDI_MigrationMappingUtility.updateCustomSettings(
            BDI_MigrationMappingUtility.HELP_TEXT,
            String.valueOf(Metadata.DeployStatus.Succeeded));
    """

    data_import_field_mapping_apex = """
        BDI_MigrationMappingUtility migrationMappingUtility =
            new BDI_MigrationMappingUtility(
                new BDI_MigrationMappingHelper());
        migrationMappingUtility.migrateHelpTextToCustomMetadata();
        Id deploymentId = CMT_MetadataAPI.deployMetadata(
            migrationMappingUtility.queuedMetadataTypesForDeploy,
            new BDI_MigrationMappingUtility.DeploymentCallback());
    """

    task_options = {
        "mode": {
            "description": "'Help Text' or 'Data Import Field Mapping'",
            "required": True,
        },
    }

    def get_org_namespace_prefix(self):
        managed = self.options.get("managed") or False
        namespaced = self.options.get("namespaced") or False

        if managed or namespaced:
            return "npsp__"
        else:
            return ""

    def _validate_options(self):
        if self.options.get("mode") == "Help Text":
            self.options["apex"] = self.help_text_apex
        elif self.options.get("mode") == "Data Import Field Mapping":
            self.options["apex"] = self.data_import_field_mapping_apex
        else:
            raise TaskOptionsError(
                "You must specify mode as either 'Help Text' or 'Data Import Field Mapping'"
            )

        super()._validate_options()

    def _run_task(self):
        super()._run_task()
        self.logger.info("Deploying BDI mode {mode}".format(mode=self.options.get("mode")))
        for i in range(0, 600):
            if self._get_di_mode() == self.options.get("mode"):
                return
            self.logger.info("Waiting for BDI metadata to deploy.")
            time.sleep(3)
        raise AssertionError("Data Import mode never updated!")

    def _get_di_mode(self):
        soql = "SELECT {token}Field_Mapping_Method__c FROM {token}Data_Import_Settings__c"
        soql = soql.format(token=self.get_org_namespace_prefix())
        res = self.sf.query_all(soql)
        if res["records"]:
            return res["records"][0][
                "{token}Field_Mapping_Method__c".format(
                    token=self.get_org_namespace_prefix()
                )
            ]
