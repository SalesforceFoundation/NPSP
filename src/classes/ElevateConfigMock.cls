public with sharing class ElevateConfigMock implements System.StubProvider {
    public Boolean isElevateCustomer;
    public Object handleMethodCall(Object stubbedObject,
            String stubbedMethodName,
            Type returnType,
            List<Type> listOfParamTypes,
            List<String> listOfParamNames,
            List<Object> listOfArgs) {
        switch on stubbedMethodName {
            when 'isElevateCustomer' {
                return isElevateCustomer;
            }
        }
        return null;
    }
}