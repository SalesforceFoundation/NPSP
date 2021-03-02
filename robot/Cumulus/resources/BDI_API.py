from tasks.salesforce_robot_library_base import SalesforceRobotLibraryBase


class BDI_API(SalesforceRobotLibraryBase):
    def configure_BDI(self, mode):
        return self._run_subtask("set_bdi_mapping_mode", mode=mode)

    def _get_di_mode(self):
        token = self.get_npsp_namespace_prefix()
        soql = "SELECT {token}Field_Mapping_Method__c FROM {token}Data_Import_Settings__c"
        soql = soql.format(token=token)
        res = self.cumulusci.sf.query_all(soql)
        return res['records'][0]['{token}Field_Mapping_Method__c'.format(token=token)]

    def batch_data_import(self, batchsize):
        """"Do a BDI import using the API and wait for it to complete"""
        self._run_apex("""BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
                ID ApexJobId = Database.executeBatch(bdi, %d);
                """ % int(batchsize))

        self._batch_apex_wait("BDI_DataImport_BATCH")
