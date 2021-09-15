public interface ILegacyHouseholds {
    IHouseholdName householdName();

    /**
     * @param legacyHouseholdMembers Used to merge Members of other Legacy Household into
     * the Household(s) in the domain.
     * @param mergeHousehold When true the incoming Contact's entire Household is merged
     * into this one.  Otherwise, the Contact is removed from its previous Household.
     * The Contact's previous Household is deleted if it has no remaining members.
     */
    void add(ILegacyHouseholdMembers legacyHouseholdMembers, Boolean mergeHousehold);

    /**
     * @param contacts Used to add new Contacts to a Household.
     */
    void add(IContacts contacts);
}