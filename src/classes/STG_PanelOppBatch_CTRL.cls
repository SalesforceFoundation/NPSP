public with sharing class STG_PanelOppBatch_CTRL extends STG_Panel { 

    public STG_PanelOppBatch_CTRL() {
        isRunningBatch = false;
    }
    
    public override string idPanel() { return 'idPanelOppBatch'; }
    
    public boolean isRunningBatch { get; set; }
    
    public PageReference runBatch() {
        isRunningBatch = true;

        // run batch rollup
        RLLP_OppRollup rg = new RLLP_OppRollup();
        rg.rollupAll();        
        return null;
    }

}