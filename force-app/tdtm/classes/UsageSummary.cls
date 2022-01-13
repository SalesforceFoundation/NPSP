public without sharing class UsageSummary {

    private List<UsageIncrement> increments;

    public UsageSummary(List<UsageIncrement> usageIncrements){
        this.increments = usageIncrements;
    }

    public Integer totalQueries(){
        Integer total = 0;
        for (UsageIncrement usageIncrement : increments) {
            total += usageIncrement.queries();
        }
        return total;
    }

    public Integer totalCpu(){
        Integer total = 0;
        for (UsageIncrement usageIncrement : increments) {
            total += usageIncrement.cpuTime();
        }
        return total;
    }

    public Integer totalDmlRows(){
        Integer total = 0;
        for (UsageIncrement usageIncrement : increments) {
            total += usageIncrement.dmlRows();
        }
        return total;
    }

    public Long totalTimeMillis(){
        Long total = 0;
        for (UsageIncrement usageIncrement : increments) {
            total += usageIncrement.timeMillis();
        }
        return total;
    }

    public Integer timesRun(){
        return increments.size();
    }

    public String format() {
        JSONGenerator jsonGenerator = JSON.createGenerator(true);
        jsonGenerator.writeStartObject();
        jsonGenerator.writeNumberField('timesRun', timesRun());
        jsonGenerator.writeNumberField('timeMillis', totalTimeMillis());
        jsonGenerator.writeNumberField('queries', totalQueries());
        jsonGenerator.writeNumberField('cpu', totalCpu());
        jsonGenerator.writeNumberField('dmlRows', totalDmlRows());
        jsonGenerator.close();
        return jsonGenerator.getAsString();
    }

}