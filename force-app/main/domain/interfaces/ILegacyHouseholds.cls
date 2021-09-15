public interface ILegacyHouseholds {
    /**
     * @param legacyHouseholdId
     *
     * @return
     */
    IHouseholdName householdNameFor(LegacyHouseholdId legacyHouseholdId);

    /**
     * @param householdMembers Used to merge Members of other Households into
     * the Household(s) in the domain.
     * @param mergeHousehold When true the incoming Contact's entire Household is merged
     * into this one.  Otherwise, the Contact is removed from its previous Household.
     * The Contact's previous Household is deleted if it has no remaining members.
     */
    void add(IHouseholdMembers householdMembers, Boolean mergeHousehold);

    /**
     * @param contacts Used to add new Contacts to a Household.
     */
    void add(IContacts contacts);
}