public interface IAddress {

    String street();
    String street2();
    String city();
    String state();
    String postalCode();
    String country();
    Boolean isEqualTo(IAddress other, Boolean includeAddressType);

    SObject getRecord();

    String getType();

}