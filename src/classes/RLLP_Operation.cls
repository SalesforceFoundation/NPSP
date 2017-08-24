public with sharing class RLLP_Operation {

    public enum RollupType {COUNT, SUM, AVERAGE, LARGEST, SMALLEST, FIRST, LAST, YEARS_DONATED, CURRENT_STREAK}

    public Schema.SObjectField destinationField;
    public Schema.SObjectField resultField;
    public RollupType type;

    //figure this out further
    public String year;

    public RLLP_Operation(Schema.SObjectField destinationField, RollupType type) {
        this.type = type;
        this.destinationField = destinationField;
    }
    public RLLP_Operation(Schema.SObjectField destinationField, RollupType type, Schema.SObjectField resultField) {
        this.type = type;
        this.destinationField = destinationField;
        this.resultField = resultField;
    }
    public RLLP_Operation(Schema.SObjectField destinationField, RollupType type, String year) {
        this.type = type;
        this.destinationField = destinationField;
        this.year = year;
    }

    //CMT constructor
    //public RLLP_Operation(Operation__cmt){}
}