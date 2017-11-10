/* ======================================================================================================= */
/* **************                   THIS CLASS WILL BE REPLACED WITH A TBD CLASS            ************** */
/* ======================================================================================================= */
public class RLLP_Operation {

    public enum RollupType {
        COUNT,
        SUM,
        AVERAGE,
        LARGEST,
        SMALLEST,
        FIRST,
        LAST,
        YEARS_DONATED,
        CURRENT_STREAK,
        BEST_YEAR,
        BEST_YEAR_TOTAL
    }


    /**
     * @description Converts the enum strings into friendly strings for the pick-lists.
     */
    public static Map<RLLP_Operation.RollupType, String> getRollupOperationTypes() {
        return new Map<RLLP_Operation.RollupType, String>{
                RLLP_Operation.RollupType.COUNT => 'Count',
                RLLP_Operation.RollupType.SUM => 'Sum',
                RLLP_Operation.RollupType.AVERAGE => 'Average',
                RLLP_Operation.RollupType.LARGEST => 'Largest',
                RLLP_Operation.RollupType.SMALLEST => 'Smallest',
                RLLP_Operation.RollupType.FIRST => 'First',
                RLLP_Operation.RollupType.LAST => 'Last',
                RLLP_Operation.RollupType.YEARS_DONATED => 'Years Donated',
                RLLP_Operation.RollupType.CURRENT_STREAK => 'Current Streak',
                RLLP_Operation.RollupType.BEST_YEAR => 'Best Year',
                RLLP_Operation.RollupType.BEST_YEAR_TOTAL => 'Best Year Total'
        };
    }

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