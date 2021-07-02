public interface IHouseholdSelector {

    IHouseholds findByIdWithOneContactAndGift(Set<Id> ids);
}