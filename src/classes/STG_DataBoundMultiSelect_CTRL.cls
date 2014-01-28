public with sharing class STG_DataBoundMultiSelect_CTRL {

    public list<SelectOption> listSelectOption { get; set; }
    public boolean isEditMode { get; set; }
    public boolean isDisabled { get; set; }
    public SObject sobjBinding { get; set; }
    public string strField { get; set; }
    
    public STG_DataBoundMultiSelect_CTRL() {
    	isDisabled = false;
    	isEditMode = false;
    }
    
    public string strValues { 
    	get {
    		if (strValues == null) {
    			strValues = string.valueOf(sobjBinding.get(strField));
    		}
    		return strValues;
    	}
    	private set; 
    }

    public list<string> listStrValues {
        get {
            if (listStrValues == null && strValues != null) {
                listStrValues = strValues.split(';',0);
            }
            return listStrValues;
        }
        set {
        	listStrValues = value;
        	strValues = '';
            for (string str : listStrValues) {
            	strValues += str + ';';
            }
            if (strValues != '')
                strValues = strValues.left(strValues.length()-1);
            sobjBinding.put(strField, strValues);	
        }
    }
    
    
}