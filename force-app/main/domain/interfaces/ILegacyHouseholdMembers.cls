public interface ILegacyHouseholdMembers {

    List<LegacyHouseholdId> householdIds();
    ILegacyHouseholdMembers membersFor(LegacyHouseholdId aLegacyHouseholdId);
    void setAddress(IAddress anAddress);
}