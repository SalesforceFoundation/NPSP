public with sharing class ERR_ExceptionData {
    public String exceptionType;
    
    // This will contain the error message
    // If it is not an DML error
    public String errorMessage;

    // These fields will only be used if it is an DML Error message
    // The integer is for the row which has an error
    public Map<Integer, String> DMLErrorMessageMapping;
    public Map<Integer, List<String>> DMLErrorFieldNameMapping;

    public ERR_ExceptionData(Exception e) {
        exceptionType = e.getTypeName();

        DMLErrorMessageMapping = new Map<Integer, String>();
        DMLErrorFieldNameMapping = new Map<Integer, List<String>>();
      
        if (exceptionType == new System.DmlException().getTypeName()) {
            DmlException dmlCastedException = (DmlException)e;
            for (Integer i = 0; i < dmlCastedException.getNumDml(); i++) {
                
                DMLErrorMessageMapping.put(i, dmlCastedException.getDmlMessage(i));
             
                if (dmlCastedException.getDmlFieldNames(i).size() > 0) {
                    DMLErrorFieldNameMapping.put(i, dmlCastedException.getDmlFieldNames(i));
                }
            }
        } else {
            errorMessage = e.getMessage();
        }
    }

    public ERR_ExceptionData(String errorMessage) {
        this.errorMessage = errorMessage;
    }

    public static String createExceptionWrapperJSONString(String errorMessage) {
        ERR_ExceptionData exceptionWrapper = new ERR_ExceptionData(errorMessage);
        String JSONExceptionData = JSON.serialize(exceptionWrapper);

        return JSONExceptionData;
    }

    public static String createExceptionWrapperJSONString(Exception e) {
        DmlException dmlException = (DmlException)e;
        ERR_ExceptionData exceptionWrapper = new ERR_ExceptionData(e);
        String JSONExceptionData = JSON.serialize(exceptionWrapper);

        return JSONExceptionData;
    }
}
