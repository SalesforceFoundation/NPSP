public with sharing class OPP_OpportunityNaming {
/*
Given a list of opportunities
Compile all field names from all specs
Query for opps and related fields from specs
compile names from opportunities
add names to opps
update opps


*/
    
    private static string chLToken = '{!';
    private static string chRToken = '}';

    public static set<string> getFieldNamesFromSpec(string spec) {
        set<string> setStrField = new set<string>();
        
        // First, instantiate a new Pattern object looking for {!...}
        Pattern MyPattern = Pattern.compile('\\{![^\\{!]*\\}');       
        //Pattern MyPattern = Pattern.compile('\\{!*\\}');       
        // Then instantiate a new Matcher object 
        Matcher MyMatcher = MyPattern.matcher(spec);
        
        while (MyMatcher.find()) {
            // get the fieldname without the {}'s
            string strField = spec.substring(MyMatcher.start() + chLToken.length(), MyMatcher.end()-1);
            setStrField.add(strField.trim());
        }
        return setStrField;
    }

    public static string getOppQuery(set<string> fields) {
        string result = 'SELECT Id, Name, RecordTypeId, RecordType.Name';
        for (string field : fields) {
            result += ', ' + field;
        }
        result += ' FROM Opportunity';
        return result;
    }


    public static string replaceFieldNamesWithValues(Opportunity opp, Opportunity_Naming_Settings__c ons) {
        string result = ons.Opportunity_Name_Format__c;
        
        // First, instantiate a new Pattern object looking for {!...} without any nested {'s.
        Pattern MyPattern = Pattern.compile('\\{![^\\{!]*\\}');       
        //Pattern MyPattern = Pattern.compile('\\{!*\\}');       
        // Then instantiate a new Matcher object 
        Matcher MyMatcher = MyPattern.matcher(ons.Opportunity_Name_Format__c);
        
        while (MyMatcher.find()) {
            // get the fieldname without the {! }
            string strField = ons.Opportunity_Name_Format__c.substring(MyMatcher.start() + chLToken.length(), MyMatcher.end()-chRToken.length());
            
            // separate cross object references, i.e. account.name
            list<string> splitField = (strField.split('\\.',0));
            
            string fieldName = splitField[splitField.size()-1];
            splitField.remove(splitField.size()-1);

            sObject thisObj = opp;
            for (string parentObj : splitField) {
                thisObj = thisObj.getsObject(parentObj);
            }

            //if this field is a date or datetime field, follow the format supplied in the settings
            string val = getFieldValue(thisObj, fieldName, ons);

            // add back the {}'s for string substitution
            strField = chLToken + strField + chRToken;
            if (val == null) {   
                // eat potential trailing space
                result = result.replace(strField + ' ', '');
                // eat potential leading space
                result = result.replace(' ' + strField, '');
            }
            result = result.replace(strField, val == null ? '' : val);
        }
        return result;
    }

    //Returns the value of a field as a string, while respecting the date format specified in settings
    public static string getFieldValue(sObject obj, string fieldName, Opportunity_Naming_Settings__c ons) {
        Schema.DisplayType dt = obj.getSObjectType().getDescribe().fields.getMap().get(fieldName).getDescribe().getType();
        string result = '';

        //If this is a Date or DateTime field, use the specified formatting if there is one
        if (dt == Schema.DisplayType.Date || dt == Schema.DisplayType.DateTime) {
            DateTime d = (DateTime) obj.get(fieldName.trim());
            if (!String.isBlank(ons.Date_Format__c)) {
                result = d.format(ons.Date_Format__c);
            } else {
                result = d.format('yyyy.MM.dd');
            }
        } else {
            result = (String) obj.get(fieldName.trim());
        }

        return result;
    }
}