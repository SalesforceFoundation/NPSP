public with sharing class UTIL_Where {
    public class SoqlException extends Exception {}

	public Enum Operator {
		EQUALS,
		NOT_EQUALS
	}

	
	private static String operatorToString(Operator operant){
    	String result = null;

        if (operant == Operator.EQUALS) { result = '='; }       
        else if (operant == Operator.NOT_EQUALS) { result = '!='; }   

        return result;
    }

	public static Boolean meetsCriteria(List<Boolean> matchResult, String logicOperator) {
		if (matchResult == null || matchResult.isEmpty()) {
			return false;
		}

		if (logicOperator == AND_OPERATOR) {
			for (Boolean result : matchResult) {
				if (!result) {
					return false;
				}
			}
			return true;

		} else {
			for (Boolean result : matchResult) {
				if (result) {
					return true;
				}
			}
			return false;
		}
	}
    

	public static final String AND_OPERATOR = 'AND';
	public static final String OR_OPERATOR = 'OR';

    private List<GroupExpression> groups;
    private String logicOperator = AND_OPERATOR;

    @TestVisible private Boolean isFilterable {
        get {
            if (isFilterable == null) {
                isFilterable = true;
                for (GroupExpression groupExp : groups) {
                    if (!groupExp.isFilterable()) {
                        isFilterable = false;
                        break;
                    }
                }
            }
            return isFilterable;
        }
        set;
    }
    @TestVisible private Boolean isNameField {
        get {
            if (isNameField == null) {
                isNameField = true;
                for (GroupExpression groupExp : groups) {
                    if (!groupExp.isNameField()) {
                        isNameField = false;
                        break;
                    }
                }
            }
            return isNameField;
        }
        set;
    }

    public UTIL_Where() {
        groups = new List<GroupExpression>();
    }

    public UTIL_Where add(GroupExpression groupExp) {
        groups.add(groupExp);

        return this;
    }

    public UTIL_Where add(FieldExpression fieldExp) {
        groups.add(new GroupExpression().add(fieldExp));

        return this;
    }

    public UTIL_Where withOr() {
        logicOperator = OR_OPERATOR;
        return this;
    }

    public Boolean isFilterable() {
        return isFilterable;
    }

    public Boolean isNameField() {
        return isNameField;
    }

    public String build() { 
        List<String> result = new List<String>();
        Boolean isFilterable = isFilterable();

        if (isFilterable) {//SOQL
            for (GroupExpression groupExp : groups) {
                result.add(groupExp.toString());
            }
        } else {//SOSL
            for (GroupExpression groupExp : groups) {
                result.add(groupExp.getSearchValue());
            }
        }

        return String.join(result, ' ' + logicOperator + ' ');
    }

    public List<sObject> filter(List<sObject> records) {
        List<sObject> result = new List<sObject>();
        for (sObject record : records) {
            if (meetsCriteria(record)) {
                result.add(record);
            }
        }

        return result;
    }

    public Set<String> getFields() {
        Set<String> result = new Set<String>();
        for (GroupExpression groupExp : groups) {
            result.addAll(groupExp.getFields());
        }

        return result;
    }

    @TestVisible 
	private Boolean meetsCriteria(sObject record) {
		List<Boolean> matchResult = new List<Boolean>();

        for (GroupExpression groupExp : groups) {
            matchResult.add(groupExp.meetsCriteria(record));
        }

		return meetsCriteria(matchResult, logicOperator);
    }

    public static GroupExpression AndGroup() {
        return new GroupExpression();
    }

    public static GroupExpression OrGroup() {
        return new GroupExpression().withOr();
    }

    public class GroupExpression { 
        private List<FieldExpression> fieldExpressions;
        private String logicOperator = AND_OPERATOR;
        private Boolean isFilterable {
            get {
                if (isFilterable == null) {
                    isFilterable = true;
                    for (FieldExpression fieldExp : fieldExpressions) {
                        if (!fieldExp.isFilterable()) {
                            isFilterable = false;
                            break;
                        }
                    }
                }
                return isFilterable;
            }
            set;
        }
        private Boolean isNameField {
            get {
                if (isNameField == null) {
                    isNameField = true;
                    for (FieldExpression fieldExp : fieldExpressions) {
                        if (!fieldExp.isNameField) {
                            isNameField = false;
                            break;
                        }
                    }
                }
                return isNameField;
            }
            set;
        }

        public GroupExpression() {
            fieldExpressions = new List<FieldExpression>();
        }

        public GroupExpression withOr() {
            logicOperator = OR_OPERATOR;
            return this;
        }

        public GroupExpression add(FieldExpression fieldExp) {
            fieldExpressions.add(fieldExp);

            return this;
        }

        public Boolean isFilterable() {
            return isFilterable;
        }

        public Boolean isNameField() {
            return isNameField;
        }

        public override String toString() {
            List<String> result = new List<String>();

            for (FieldExpression fieldExp : fieldExpressions) {
                result.add(fieldExp.toString());
            }
            
            if (result.isEmpty()) {
                return '';
            }

            return result.size() == 1
                ? result[0] 
                : '(' + String.join(result, ' ' + logicOperator + ' ') + ')';
        }

        public Set<String> getFields() {
            Set<String> result = new Set<String>();
            for (FieldExpression fieldExp : fieldExpressions) {
                result.add(fieldExp.getFieldPath());
            }

            return result;
        }

        public String getSearchValue() {
            List<String> result = new List<String>();

            for (FieldExpression fieldExp : fieldExpressions) {
                String searchValue = fieldExp.getSearchValue();

                if (String.isNotBlank(searchValue)) {
                    result.add(searchValue);
                }
            }

            if (result.isEmpty()) {
                return '';
            }

            return result.size() == 1
                ? result[0] + '*'
                : '(' + String.join(result, ' ' + logicOperator + ' ') + ')';
        }

        public Boolean meetsCriteria(sObject record) {
            List<Boolean> matchResult = new List<Boolean>();
            for (FieldExpression fieldExp : fieldExpressions) {
                matchResult.add(fieldExp.meetsCriteria(record));
            }

            return meetsCriteria(matchResult, logicOperator);
        }
    }


    public class FieldExpression {
        private Schema.sObjectField sObjField;
        private Schema.sObjectField referenceField;
        private Operator operant;
        private Object value;

        @TestVisible private Boolean isFilterable {
            get {
                if (isFilterable == null) {
                    isFilterable = sObjField.getDescribe().isFilterable();
                }
                return isFilterable;
            }
            set;
        }
        @TestVisible private Boolean isNameField {
            get {
                if (isNameField == null) {
                    isNameField = sObjField.getDescribe().isNameField();
                }
                return isNameField;
            }
            set;
        }

        public FieldExpression(Schema.SObjectField sObjField) {
            this.sObjField = sObjField;
        }

        public FieldExpression fromRelationship(Schema.sObjectField referenceField) {
            this.referenceField = referenceField;

            return this;
        }
        
        public Boolean isFilterable() {
            return isFilterable;
        }

        public Boolean isNameField() {
            return isNameField;
        }

        public FieldExpression equals(Object value) {
            operant = Operator.EQUALS;
            this.value = value;
            return this; 
        }

        public FieldExpression notEquals(Object value) {
            operant = Operator.NOT_EQUALS;
            this.value = value;
            return this; 
        }

        private Boolean isRelationshipField() {
            return referenceField != null;
        }

        public String getRelationshipName() {
            return referenceField != null ? referenceField.getDescribe().getRelationshipName() : '';
        }

        public String getFieldPath() {
            return (isRelationshipField() ? getRelationshipName() + '.' : '') + String.valueOf(sObjField);
        }

        public String getSearchValue() {
            String skipSearchValue = '';

            if (value == null) {
                return skipSearchValue;
            }         

            if (value instanceof String || value instanceof Id) {
                if (String.isBlank(String.valueOf(value))) {
                    return skipSearchValue;
                }

                if (operant == Operator.NOT_EQUALS) {
                    throw new SoqlException('Search cannot be done for != operator');// TODO: Create a CustomLabel 
                }
               
                return String.escapeSingleQuotes((String) value);
            }

            throw new SoqlException('Invalid data type for: ' + value);// TODO: Create a CustomLabel
        }

        public override String toString() {
			if (operant == null) {
                throw new SoqlException('Field Expression Operator is required');// TODO: Create a CustomLabel
			}

            return getFieldPath() + ' ' + operatorToString(operant) + ' ' + toLiteral(value);
        }
		
        private String toLiteral(Object value) {
            if (value == null) {
                return 'null';
            }

            if (value instanceof String || value instanceof Id) {
                return String.isBlank(String.valueOf(value)) 
                    ? 'null' 
                    : '\'' + String.escapeSingleQuotes((String) value) + '\'';
            }

            throw new SoqlException('Invalid data type for: ' + value);// TODO: Create a CustomLabel
        }

		public Boolean meetsCriteria(sObject record) {
            if (isRelationshipField()) {
                sObject referenceSObject = record.getSObject(getRelationshipName());

                return referenceSObject == null 
                    ? false
                    : isMatching(referenceSObject.get(String.valueOf(sObjField)));

            } 
			
			return isMatching(record.get(String.valueOf(sObjField)));
        }

        @TestVisible private Boolean isMatching(Object fieldValue) {
            if (operant == Operator.EQUALS) {
                return value == null 
					? String.isBlank(String.valueOf(fieldValue))
					: String.valueOf(value).equalsIgnoreCase(String.valueOf(fieldValue));

            } else if (operant == Operator.NOT_EQUALS) {
                return value == null 
					? String.isNotBlank(String.valueOf(fieldValue))
					: !String.valueOf(value).equalsIgnoreCase(String.valueOf(fieldValue));
				
            } else {
                throw new SoqlException('Invalid operator: ' + operant.name());// TODO: Create a CustomLabel
            }
        }

    }

}