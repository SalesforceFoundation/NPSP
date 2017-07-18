public class RLLP_Exclusion {
    //can we make the constant for exclusion a field reference? Like a custom settings name for our existing settings based stuff?
    //the other option is to do a migration when they switch on new rollups by copying the values into the new CMT fields

    enum Comparison {EQUALS, NOT_EQUALS, GREATER, LESS, GREATER_OR_EQUAL, LESS_OR_EQUAL, STARTS_WITH, CONTAINS}
    
    public Schema.SObjectType objectType;
    public Schema.SObjectField field;
    public Comparison operator;
    public String constant;

    private Schema.SOAPType fieldType = field.getDescribe().getSOAPType();

    public Boolean isExcluded(SObject detail) {
        if (detail.getSObjectType() != objectType) {
            //throw exception
        }
        

        //TODO: verify type of fields is the same when allowing externally defined types
        Object fieldValue = detail.get(field);

        if (fieldValue == null) {//todo: this isn't right
            if (String.isBlank(constant)) {
                return true;
            } else {
                return false;
            }
        }


        if (fieldType == Schema.SOAPType.Boolean) {
            return compareFields((Boolean)fieldValue, Boolean.valueOf(constant));
        } else if (fieldType == Schema.SOAPType.Date) {
            return compareFields((Date)fieldValue, Date.valueOf(constant));
        }

        return false;
    }

    private Boolean compareFields(Boolean fieldValue, Boolean constantValue) {
        if (operator == Comparison.EQUALS) {
            return fieldValue == constantValue;
        } else if (operator == Comparison.NOT_EQUALS) {
            return fieldValue != constantValue;
        }
        return false;
    }

    private Boolean compareFields(Date fieldValue, Date constantValue) {
        if (operator == Comparison.EQUALS) {
            return fieldValue == constantValue;
        } else if (operator == Comparison.NOT_EQUALS) {
            return fieldValue != constantValue;
        } else if (operator == Comparison.GREATER) {
            return fieldValue > constantValue;
        } else if (operator == Comparison.LESS) {
            return fieldValue < constantValue;
        } else if (operator == Comparison.GREATER_OR_EQUAL) {
            return fieldValue >= constantValue;
        } else if (operator == Comparison.LESS) {
            return fieldValue < constantValue;
        } else if (operator == Comparison.LESS_OR_EQUAL) {
            return fieldValue <= constantValue;
        }
        
        return false;
    }

/*
    Boolean: EQUALS, NOT_EQUALS
    Date: EQUALS, NOT_EQUALS, GREATER, LESS, GREATER_OR_EQUAL, LESS_OR_EQUAL
    DateTime: EQUALS, NOT_EQUALS, GREATER, LESS, GREATER_OR_EQUAL, LESS_OR_EQUAL
    Double: EQUALS, NOT_EQUALS, GREATER, LESS, GREATER_OR_EQUAL, LESS_OR_EQUAL
    ID: EQUALS, NOT_EQUALS
    Integer: EQUALS, NOT_EQUALS, GREATER, LESS, GREATER_OR_EQUAL, LESS_OR_EQUAL
    String EQUALS, NOT_EQUALS, STARTS_WITH, CONTAINS
*/
}