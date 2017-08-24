public class RLLP_Exclusion {
    //can we make the constant for exclusion a field reference? Like a custom settings name for our existing settings based stuff?
    //the other option is to do a migration when they switch on new rollups by copying the values into the new CMT fields

    public enum Operators {EQUALS, NOT_EQUALS, GREATER, LESS, GREATER_OR_EQUAL, LESS_OR_EQUAL, STARTS_WITH, CONTAINS, DOES_NOT_CONTAIN, IS_INCLUDED, IS_NOT_INCLUDED}

/*
    Boolean: EQUALS, NOT_EQUALS
    Date: EQUALS, NOT_EQUALS, GREATER, LESS, GREATER_OR_EQUAL, LESS_OR_EQUAL
    DateTime: EQUALS, NOT_EQUALS, GREATER, LESS, GREATER_OR_EQUAL, LESS_OR_EQUAL
    Double: EQUALS, NOT_EQUALS, GREATER, LESS, GREATER_OR_EQUAL, LESS_OR_EQUAL
    ID: EQUALS, NOT_EQUALS
    Integer: EQUALS, NOT_EQUALS, GREATER, LESS, GREATER_OR_EQUAL, LESS_OR_EQUAL
    String: EQUALS, NOT_EQUALS, STARTS_WITH, CONTAINS
*/

    public final Schema.SObjectType objectType; //since this can be the detail, the detail's parent {opportunity for payment rollups}, or the attribution object, have RLLP_Definition split out exclusions per object type
    public final Schema.SObjectField field;
    public final Operators operator;
    public final String constant;

    public final ICompare compare;

    public interface ICompare { Boolean isExcluded(SObject sobj, Schema.SObjectField field, Operators operator, String constant); }

    public RLLP_Exclusion(Schema.SObjectType objectType, Schema.SObjectField field, Operators operator, String constant) {
        this.objectType = objectType;
        this.field = field;
        this.operator = operator;
        this.constant = constant;
        this.compare = (ICompare)converters.get(field.getDescribe().getSOAPType()).newInstance();
    }

/* TODO -> constructor for custom metadata type
    public RLLP_Exclusion(Exclusion__cmt) {

    }
*/
    public Boolean isExcluded(SObject sobj) {
        return compare.isExcluded(sobj, field, operator, constant);
    }

    private static final Map<SoapType, Type> converters = new Map<SoapType, Type>{
        SoapType.BOOLEAN    => CompareBooleans.class,
        SoapType.DOUBLE     => CompareDoubles.class,
        SoapType.DATE       => CompareDates.class,
        SoapType.DATETIME   => CompareDateTimes.class,
        SoapType.ID         => CompareIds.class,
        SoapType.INTEGER    => CompareIntegers.class,
        SoapType.STRING     => CompareStrings.class
    };

    public class CompareBooleans implements ICompare {
        public Boolean isExcluded(SObject sobj, Schema.SObjectField field, Operators operator, String constant) {
            Boolean fieldValue = (Boolean)sobj.get(field);
            Boolean constantValue = Boolean.valueOf(constant);

            //if (fieldValue == null || doubleConstant == null) {
            //let's see what the results are if we don't handle null cases

            if (operator == Operators.EQUALS) {
                return fieldValue == constantValue;
            } else if (operator == Operators.NOT_EQUALS) {
                return fieldValue != constantValue;
            }
            return false;
        }
    }

    public class CompareDoubles implements ICompare {
        public Boolean isExcluded(SObject sobj, Schema.SObjectField field, Operators operator, String constant) {
            Double fieldValue = (Double)sobj.get(field);
            Double constantValue = Double.valueOf(constant);

            if (operator == Operators.EQUALS) {
                return fieldValue == constantValue;
            } else if (operator == Operators.NOT_EQUALS) {
                return fieldValue != constantValue;
            } else if (operator == Operators.GREATER) {
                return fieldValue > constantValue;
            } else if (operator == Operators.LESS) {
                return fieldValue < constantValue;
            } else if (operator == Operators.GREATER_OR_EQUAL) {
                return fieldValue >= constantValue;
            } else if (operator == Operators.LESS) {
                return fieldValue < constantValue;
            } else if (operator == Operators.LESS_OR_EQUAL) {
                return fieldValue <= constantValue;
            }
            return false;
        }
    }

    public class CompareDates implements ICompare {
        public Boolean isExcluded(SObject sobj, Schema.SObjectField field, Operators operator, String constant) {
            Date fieldValue = (Date)sobj.get(field);

            Date constantValue = System.today().addDays(Integer.valueOf(constant));

            if (operator == Operators.EQUALS) {
                return fieldValue == constantValue;
            } else if (operator == Operators.NOT_EQUALS) {
                return fieldValue != constantValue;
            } else if (operator == Operators.GREATER) {
                return fieldValue > constantValue;
            } else if (operator == Operators.LESS) {
                return fieldValue < constantValue;
            } else if (operator == Operators.GREATER_OR_EQUAL) {
                return fieldValue >= constantValue;
            } else if (operator == Operators.LESS) {
                return fieldValue < constantValue;
            } else if (operator == Operators.LESS_OR_EQUAL) {
                return fieldValue <= constantValue;
            }
            return false;
        }
    }

    public class CompareDateTimes implements ICompare {
        public Boolean isExcluded(SObject sobj, Schema.SObjectField field, Operators operator, String constant) {
            DateTime fieldValue = (DateTime)sobj.get(field);
            DateTime constantValue = DateTime.valueOf(constant);

            if (operator == Operators.EQUALS) {
                return fieldValue == constantValue;
            } else if (operator == Operators.NOT_EQUALS) {
                return fieldValue != constantValue;
            } else if (operator == Operators.GREATER) {
                return fieldValue > constantValue;
            } else if (operator == Operators.LESS) {
                return fieldValue < constantValue;
            } else if (operator == Operators.GREATER_OR_EQUAL) {
                return fieldValue >= constantValue;
            } else if (operator == Operators.LESS) {
                return fieldValue < constantValue;
            } else if (operator == Operators.LESS_OR_EQUAL) {
                return fieldValue <= constantValue;
            }
            return false;
        }
    }

    public class CompareIds implements ICompare {
        public Boolean isExcluded(SObject sobj, Schema.SObjectField field, Operators operator, String constant) {
            Id fieldValue = (Id)sobj.get(field);
            Id constantValue = String.isBlank(constant) ? null : Id.valueOf(constant);

            if (operator == Operators.EQUALS) {
                return fieldValue == constantValue;
            } else if (operator == Operators.NOT_EQUALS) {
                return fieldValue != constantValue;
            }

            return false;
        }
    }

    public class CompareIntegers implements ICompare {
        public Boolean isExcluded(SObject sobj, Schema.SObjectField field, Operators operator, String constant) {
            Integer fieldValue = (Integer)sobj.get(field);
            Integer constantValue = Integer.valueOf(constant);

            if (operator == Operators.EQUALS) {
                return fieldValue == constantValue;
            } else if (operator == Operators.NOT_EQUALS) {
                return fieldValue != constantValue;
            } else if (operator == Operators.GREATER) {
                return fieldValue > constantValue;
            } else if (operator == Operators.LESS) {
                return fieldValue < constantValue;
            } else if (operator == Operators.GREATER_OR_EQUAL) {
                return fieldValue >= constantValue;
            } else if (operator == Operators.LESS) {
                return fieldValue < constantValue;
            } else if (operator == Operators.LESS_OR_EQUAL) {
                return fieldValue <= constantValue;
            }
            return false;
        }
    }

    public class CompareStrings implements ICompare {
        public Boolean isExcluded(SObject sobj, Schema.SObjectField field, Operators operator, String constant) {
            //includes, excludes, etc
            return false;
        }
    }
}