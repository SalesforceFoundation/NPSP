public with sharing class FieldMappings extends fflib_SObjects {

    public FieldMappings(List<Data_Import_Field_Mapping__mdt> records){
        super(records);
    }

    private Data_Import_Field_Mapping__mdt getMappingByDevName(String devName) {
        for (Data_Import_Field_Mapping__mdt d :
                (List<Data_Import_Field_Mapping__mdt>) getRecords()) {
            if (d.DeveloperName == devName) {
                return d;
            }
        }
        return null;
    }

    /**
     * @param devName DeveloperName of the field mapping to check
     * @description Some Elements have no field mappings but should still be on the
     * layout.  This method looks to see if the field mapping exists and is deleted.
     */
    public Boolean isDeleted(String devName) {
        Data_Import_Field_Mapping__mdt d = getMappingByDevName(devName);
        if (d != null && d.Is_Deleted__c) {
            return true;
        } else {
            return false;
        }
    }
}