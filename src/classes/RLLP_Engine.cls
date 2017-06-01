public class RLLP_Engine {
    
    public RLLP_Engine(List<RLLP_Operation> operations) {
        for (RLLP_Operation operation : operations) {
            if (!hasYearly && operation.year != null) {
                hasYearly = true;
            }
            if (!hasSmallest && operation.type == RLLP_Operation.RollupType.SMALLEST) {
                hasSmallest = true;
            }
            if (!hasLargest && operation.type == RLLP_Operation.RollupType.LARGEST) {
                hasLargest = true;
            }
            if (!hasFirst && operation.type == RLLP_Operation.RollupType.FIRST) {
                hasFirst = true;
            }
            if (!hasLast && operation.type == RLLP_Operation.RollupType.SMALLEST) {
                hasLast = true;
            }
        }
    }

    public class Sum {
        Integer count = 0;
        Double total = 0;

        void add(Double amount) {
            count ++;
            total += amount;
        }

        Double average() {
            if (count==0) return 0;
            return total/count;
        }
    }

    Sum total = new Sum();
    
    Map<Integer, Sum> yearly = new Map<Integer, Sum>();
    
    SObject smallest;
    Double smallestAmount;
    
    SObject largest;
    Double largestAmount;
    
    SObject first;
    Date firstDate;
    
    SObject last;
    Date lastDate;

    Boolean hasYearly = false;
    Boolean hasSmallest = false;
    Boolean hasLargest = false;
    Boolean hasFirst = false;
    Boolean hasLast = false;

    public void process(SObject obj, Date closeDate, Double amount) {            
        total.add(amount);

        if (this.hasYearly) {
            Integer year = RLLP_FiscalYears.getYear(closeDate);
            if (!yearly.containsKey(year)) {
                Sum s = new Sum();
                yearly.put(year, s);
            }
            yearly.get(year).add(amount);
        }

        //$0 as smallest amount? or exclude it? or provide a setting for the behavior
        if (this.hasSmallest) {
            if (smallest == null || amount < smallestAmount) {
                smallest = obj;
                smallestAmount = amount;
            }
        }
        if (this.hasLargest) {
            if (largest == null || amount > largestAmount) {
                largest = obj;
                largestAmount = amount;
            }
        }
        if (this.hasFirst) {
            if (first == null || closeDate < firstDate) {
                first = obj;
                firstDate = closeDate;
            }
        }
        if (this.hasLast) {
            if (last == null || closeDate > lastDate) {
                last = obj;
                lastDate = closeDate;
            }
        }
    }

    public Object getResult(RLLP_Operation operation) {
        system.debug('njjc: ' + operation + ': ' + this);
        if (operation.year!=null) {
            if (!yearly.containsKey(operation.year)) {
                return 0;
            }
            if (operation.type == RLLP_Operation.RollupType.COUNT) {
                return yearly.get(operation.year).count;
            }
            if (operation.type == RLLP_Operation.RollupType.SUM) {
                return yearly.get(operation.year).total;
            }
        }

        if (operation.type == RLLP_Operation.RollupType.COUNT) {
            return total.count;
        }
        if (operation.type == RLLP_Operation.RollupType.SUM) {
            return total.total;
        }
        if (operation.type == RLLP_Operation.RollupType.AVERAGE) {
            return total.average();
        }

        if (operation.type == RLLP_Operation.RollupType.SMALLEST && smallest != null) {
            return smallest.get(operation.resultField);
        }
        if (operation.type == RLLP_Operation.RollupType.LARGEST && largest != null) {
            return largest.get(operation.resultField);
        }
        if (operation.type == RLLP_Operation.RollupType.FIRST && first != null) {
            return first.get(operation.resultField);
        }
        if (operation.type == RLLP_Operation.RollupType.LAST && last != null) {
            return last.get(operation.resultField);
        }
        return null;
    }

/*
    public Map<Id, RLLP_Engine> results = new Map<Id, RLLP_Engine>();

    public void processResults(SObject rollupObject) {
        if (!results.containsKey((Id)rollupObject.get('id'))) {
            return;
        }
        RLLP_Engine rollupSummary = results.get((Id)rollupObject.get('id'));
        for (RLLP_Operation operation : definition.operations) {
            Object result = rollupSummary.getResult(operation);
            rollupObject.put(operation.destinationField, result);
        }
    }



    Run all rollups for:
        A list of summary objects (contacts, accounts, etc.)
        A list of detail objects (opps/payments that were updated, etc.)
    
    Methods for:
        Each rollup operation type
        
        Exchange rates calc (ACM or standard)
        Fiscal year calc (TBD custom fiscal years)

    Classes for:
        Define fields that are being rolled up on the detail object (Amount, Date)
        Define rollup operations (eventually user-defined)
            detail object and fields (amount, date)
                may restrict user defined operations to opportunity and payment.
                decide if non-standard amount and date fields can be chosen per UDR, or only globally for all rollups of that type.
            operation type
            Integer (N Days or N Years ago)
            summary object and field
            custom exclusions
            Funky types
                Consecutive years

        Holding summary info during calculation (can I just use the results object to hold it?)
            Summary class
        Mapping Summary info to results object fields
    */

}