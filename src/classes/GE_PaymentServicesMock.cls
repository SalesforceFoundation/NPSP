public class GE_PaymentServicesMock implements StubProvider {
    private Boolean isElevateCustomer;

    public GE_PaymentServicesMock withIsElevateCustomer(Boolean isElevateCustomer) {
        this.isElevateCustomer = isElevateCustomer;
        return this;
    }

    public Boolean isElevateCustomer() {
        return this.isElevateCustomer;
    }

    public Object handleMethodCall(Object stubbedObject,
            String stubbedMethodName,
            Type returnType,
            List<Type> listOfParamTypes,
            List<String> listOfParamNames,
            List<Object> listOfArgs) {

        switch on (stubbedMethodName) {
            when 'isElevateCustomer' {
                return isElevateCustomer;
            }
        }

        return null;
    }
}