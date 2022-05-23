public class DataStagingDuplicate {        
    // the found duplicate record id returned by the Datacloud.MatchRecord.getRecord method:
    public Id duplicateId;
    // the link to the found duplicate record:
    public String duplicateUrl;
    // the decimal number returned by the Datacloud.MatchRecord.getMatchConfidence method:
    public Decimal confidenceScore;
    // the matching rule name returned by the Datacloud.MatchResult.getRule method:
    public String matchingRuleName;
    // the JSON string structure containing the result of Datacloud.FieldDiff.getName and Datacloud.FieldDiff.getDifference
    // we can use List<ComparsionResult> to deserlialize this json string into something easier to handle
    public String matchDetails;
    // match details as list 
    public List<ComparisonResult> comparisonResults;
}
