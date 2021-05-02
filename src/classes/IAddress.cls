public interface IAddress {

    //Todo: refactor until getRecord() is no longer necessary, then remove
    SObject getRecord();
    //Todo: refactor until getType() can be removed.  An Entity that knows one or more
    // addresses should be storint
    String getType();

    String street();
    String street2();
    String multilineStreet();

    String city();
    String state();
    String postalCode();
    String country();

    Decimal latitude();
    Decimal longitude();

    Boolean isEqualTo(IAddress other, Boolean includeAddressType);
    Boolean isDifferentIncludingLatLong(IAddress other);

}