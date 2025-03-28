public class Ex_DraftBillController {

    // Will be invoked from flow
    @InvocableMethod(label='Send Termsheet Record')
    public static void createDraftBills(List<Id> recordIds ){
        Map<String, Integer>ThresholdMap = new Map<String, Integer>();
        
        if(recordIds == null && recordIds.size()== 0){
            return;
        }
        String termsheetId = recordIds[0];
        
        // Get termsheet
        List<Term_Sheet__c> termsheets = [SELECT Id, Name, Start_date__c, End_date__c, Society__c,Rent_Threshold_Days__c,Brokerage_Threshold_Days__c,Transport_Threshold_Days__c,Corpus_Threshold_Days__c,MISC_Threshold_Days__c
                                          FROM  Term_Sheet__c
                                          WHERE Id = :termsheetID];
        system.debug('termsheets '+termsheets);
        if(termsheets!=null && termsheets.size()>0){
            for(Term_Sheet__c ts : termsheets){
                if(ts.Rent_Threshold_Days__c != null)
                    ThresholdMap.put('Rent Threshold',Integer.valueOf(ts.Rent_Threshold_Days__c));
                else
                    ThresholdMap.put('Rent Threshold',7 );
                if(ts.MISC_Threshold_Days__c != null)
                    ThresholdMap.put('MISC Threshold', Integer.valueOf(ts.MISC_Threshold_Days__c));
                else
                    ThresholdMap.put('MISC Threshold',7 );
                if(ts.Corpus_Threshold_Days__c != null)
                    ThresholdMap.put('Corpus Threshold', Integer.valueOf(ts.Corpus_Threshold_Days__c));
                else
                    ThresholdMap.put('Corpus Threshold',7 );
                if(ts.Brokerage_Threshold_Days__c != null)
                    ThresholdMap.put('Brokerage Threshold',Integer.valueOf(ts.Brokerage_Threshold_Days__c) );
                else
                    ThresholdMap.put('Brokerage Threshold',7 );
                if(ts.Transport_Threshold_Days__c != null)
                    ThresholdMap.put('Transport Threshold',Integer.valueOf(ts.Transport_Threshold_Days__c));
                else
                    ThresholdMap.put('Transport Threshold',7 );
                
            }
            System.debug('ThresholdMap '+ThresholdMap);
            
            Date startDate = termsheets[0].Start_date__c;
            Date endDate = termsheets[0].End_date__c;
            
            Database.executeBatch(new Ex_DraftBillControllerBatch( termsheets[0].Society__c,termsheets[0].Id, startDate, endDate, ThresholdMap),200);
            
        }
        
    }
    //same for call from lwc
    @AuraEnabled
    public static string createDraftBills(string recordId ){
        Map<String, Integer>ThresholdMap = new Map<String, Integer>();
        
        if(recordId == null || recordId == ''){
            return null;
        }
        String termsheetId = recordId;
        
        // Get termsheet
        
        List<Term_Sheet__c> termsheets = [SELECT Id, Name, Start_date__c, End_date__c, Society__c,Rent_Threshold_Days__c,Brokerage_Threshold_Days__c,Transport_Threshold_Days__c,Corpus_Threshold_Days__c,MISC_Threshold_Days__c
                                          FROM  Term_Sheet__c
                                          WHERE Id = :termsheetID];
        system.debug('termsheets '+termsheets);
        if(termsheets!=null && termsheets.size()>0){
            for(Term_Sheet__c ts : termsheets){
                if(ts.Rent_Threshold_Days__c != null)
                    ThresholdMap.put('Rent Threshold',Integer.valueOf(ts.Rent_Threshold_Days__c));
                else
                    ThresholdMap.put('Rent Threshold',7 );
                if(ts.MISC_Threshold_Days__c != null)
                    ThresholdMap.put('MISC Threshold', Integer.valueOf(ts.MISC_Threshold_Days__c));
                else
                    ThresholdMap.put('MISC Threshold',7 );
                if(ts.Corpus_Threshold_Days__c != null)
                    ThresholdMap.put('Corpus Threshold', Integer.valueOf(ts.Corpus_Threshold_Days__c));
                else
                    ThresholdMap.put('Corpus Threshold',7 );
                if(ts.Brokerage_Threshold_Days__c != null)
                    ThresholdMap.put('Brokerage Threshold',Integer.valueOf(ts.Brokerage_Threshold_Days__c) );
                else
                    ThresholdMap.put('Brokerage Threshold',7 );
                if(ts.Transport_Threshold_Days__c != null)
                    ThresholdMap.put('Transport Threshold',Integer.valueOf(ts.Transport_Threshold_Days__c));
                else
                    ThresholdMap.put('Transport Threshold',7 );
                
            }
            System.debug('ThresholdMap '+ThresholdMap);
            
            Date startDate = termsheets[0].Start_date__c;
            Date endDate = termsheets[0].End_date__c;
            try{
                
                Database.executeBatch(new Ex_DraftBillControllerBatch( termsheets[0].Society__c,termsheets[0].Id, startDate, endDate, ThresholdMap),50);
            }catch (exception e){
                system.debug('Error occured while creating draft Bills !' +e.getMessage());
                
                return e.getMessage();
            }
        }
        
        return 'success';
    }
    
    public static void createDraftBillsForTenent(List<Account>tenant , Date StartDate , Date EndDate, Map<String, Integer>ThresholdMap, string termsheetId){
        System.debug('tenant List 2'+tenant);
        List<Bill__c> draftBillsToInsert = new List<Bill__c>();
        Map<Id,List<Escalation__c>> escallationsWithTenantId = New Map<Id,List<Escalation__c>>();
        escallationsWithTenantId = getEscallationsWithTenatId(tenant);
        system.debug('getEscallationsWithTenatId '+escallationsWithTenantId);

        System.debug('heapsize 1: ' + Limits.getHeapSize());

        // Collect Hashes for Existing Bills for Duplication Check 
        Set<Id> tenantAccountIDs =  new Set<Id>();
        for (Account tenantAccount : tenant) {
            tenantAccountIDs.add(tenantAccount.Id);
        }
        Map<Id, Set<String>> hashesForBillsByTenantID = getHashesForTenantBills(tenantAccountIDs, termsheetId);
        System.debug('heapsize 4: ' + Limits.getHeapSize());

        
        // Rent Draft Bills
        for(Account acc:tenant){

            // Fetch escalations for this tenant
            List<Escalation__c> tenantEscalations = escallationsWithTenantId.get(acc.Id);
            System.debug('tenantEscalations for Current Tenant '+tenantEscalations);
            
            Bill__c rentDraftBill = new Bill__c();
            if(acc.Rent_Frequency__c != null  && acc.Rent_Eligibility__c=='Yes'){
                if (acc.Rent_Frequency__c == 'Yearly' || acc.Rent_Frequency__c == 'Half Yearly'|| acc.Rent_Frequency__c == 'Quarterly'){
                    Date currentBillDate =null;
                    if(StartDate<System.Today()){
                        currentBillDate= System.Today();
                    }else if(System.Today()<StartDate){
                        currentBillDate= StartDate;
                        if(acc.Rent_Payment_time__c == 'Specific date in Month' && acc.Rent_Specific_Date__c != null){
                            Integer day = acc.Rent_Specific_Date__c.day();
                            currentBillDate = Date.newInstance(currentBillDate.year(), currentBillDate.month(), day);
                        }
                    }
                    Date overallEndDate = EndDate;
                    Integer incrementMonths;
                    
                    if (acc.Rent_Frequency__c == 'Yearly') {
                        incrementMonths = 12; // 1 year interval
                    } else if (acc.Rent_Frequency__c == 'Half Yearly'){
                        incrementMonths = 6; // 6 months interval
                    } else if (acc.Rent_Frequency__c == 'Quarterly'){
                        incrementMonths = 3; // 6 months interval
                    } else {
                        continue;
                    }
                    
                    
                    // Generate draft bills
                    while (currentBillDate <= overallEndDate){
                        Decimal amount = 0;
                        Decimal amountPaid = 0;
                        
                        if(acc.Rent_Type__c == 'Lumpsum' &&  acc.Rent_Amount__c != null ){
                            amount = acc.Rent_Amount__c;
                            
                        }else if(acc.Rent_Type__c == 'PSF' &&  acc.Tenant_Carpet__c != null && acc.Rent_Rate__c != null){
                            amount= (acc.Tenant_Carpet__c*acc.Rent_Rate__c).setScale(2,RoundingMODE.HALF_UP);
                        }
                        if(tenantEscalations != null ){
                            for(Escalation__c esc :tenantEscalations){
                                if(currentBillDate>=esc.Start_Date__c && currentBillDate <= esc.End_Date__c && esc.Escalation__c !=null){
                                    amount+= (amount * esc.Escalation__c / 100).setScale(2, RoundingMode.HALF_UP);
                                }
                            }
                        }
                        string BillStage= 'Draft';
                        if(currentBillDate <= System.today()){
                            BillStage = 'Actual';
                        }
                        
                        // Integer thresholdDays = ThresholdMap.get('Rent Threshold');
                        Bill__c rentDraftYearly = new Bill__c(
                            Bill_Date__c = currentBillDate,
                        Amount__c = amount,
                        Charge_Name__c = 'Rental Charges',
                        Tenant__c = acc.Id,
                        Term_Sheet__c = termsheetId,
                        Bill_Stage__c = BillStage,
                        Due_Date__c = currentBillDate.addDays(ThresholdMap.get('Rent Threshold')));
                        
                        String draftBillHash = getHash(rentDraftYearly);
                        if(!hashesForBillsByTenantID.containsKey(acc.Id) || !hashesForBillsByTenantID.get(acc.Id).contains(draftBillHash)){
                            draftBillsToInsert.add(rentDraftYearly);
                        }
                        
                        // Increment the bill date based on frequency
                        currentBillDate = currentBillDate.addMonths(incrementMonths);
                    }
                }else if(acc.Rent_Frequency__c == 'Monthly' &&  acc.Rent_Payment_time__c != null && acc.Rent_Payment_time__c != 'Specific date in Month'){
                    Integer noOfDraftBiilsToCreate = getNumberOfMonths(startDate, EndDate, acc.Rent_Payment_time__c );
                    
                    for(Integer i=1; i<= noOfDraftBiilsToCreate; i++){
                        system.debug('i '+i);
                        if(System.Today()>StartDate){
                            i--;
                        }
                        Date currentMonthDate = startDate.addMonths(i); // Increment by i months
                        Date billDate = null;
                        
                        if (acc.Rent_Payment_time__c == 'Start of Month') {
                            billDate = Date.newInstance(currentMonthDate.year(), currentMonthDate.month(), 1);
                        }
                        else if (acc.Rent_Payment_time__c == 'Middle of Month') {
                            billDate = Date.newInstance(currentMonthDate.year(), currentMonthDate.month(), 15);
                        }
                        else if (acc.Rent_Payment_time__c == 'End of Month') {
                            Integer lastDay = Date.daysInMonth(currentMonthDate.year(), currentMonthDate.month());
                            billDate = Date.newInstance(currentMonthDate.year(), currentMonthDate.month(), lastDay);
                        }
                        
                        string BillStage= 'Draft';
                        if(billDate <= System.today()){
                            BillStage = 'Actual';
                        }
                        Decimal amount = 0;
                        if(acc.Rent_Type__c == 'Lumpsum' &&  acc.Rent_Amount__c != null ){
                            amount = acc.Rent_Amount__c;
                            
                        }else if(acc.Rent_Type__c == 'PSF' &&  acc.Tenant_Carpet__c != null && acc.Rent_Amount__c != null){
                            amount= (acc.Tenant_Carpet__c*acc.Rent_Amount__c).setScale(2,RoundingMODE.HALF_UP);
                        }

                        if(tenantEscalations != null ){
                            for(Escalation__c esc :tenantEscalations){
                                if(billDate>=esc.Start_Date__c && billDate <= esc.End_Date__c && esc.Escalation__c !=null){
                                    amount+= (amount * esc.Escalation__c / 100).setScale(2, RoundingMode.HALF_UP);
                                }
                            }
                        }


                        system.debug('Rent billDate'+billDate);
                        Bill__c rentalBill = new Bill__c(
                            Charge_Name__c= 'Rental Charges',
                            Tenant__c = acc.id,
                            Bill_Date__c = billDate,
                            Bill_Stage__c = BillStage,
                            Amount__c = amount,
                            Due_Date__c = billDate.addDays(ThresholdMap.get('Rent Threshold')),
                            Term_Sheet__c = termsheetId
                        );
                        
                        String draftBillHash = getHash(rentalBill);
                        if(!hashesForBillsByTenantID.containsKey(acc.Id) || !hashesForBillsByTenantID.get(acc.Id).contains(draftBillHash)){
                            draftBillsToInsert.add(rentalBill);
                        }

                        if(System.Today()>StartDate){
                            i++;
                        }
                    }
                    
                }else if(acc.Rent_Frequency__c == 'Monthly' &&  acc.Rent_Payment_time__c != null && acc.Rent_Payment_time__c == 'Specific date in Month'){
                    Integer noOfDraftBiilsToCreate = getNumberOfMonths(startDate, EndDate, acc.Rent_Payment_time__c );
                    
                    for(Integer i=1; i<= noOfDraftBiilsToCreate; i++){
                        system.debug('i '+i);
                        if(System.Today()>StartDate){
                            i--;
                        }
                        Date currentMonthDate = startDate.addMonths(i); // Increment by i months

                        Integer day = acc.Rent_Specific_Date__c.day();
                        Date billDate = Date.newInstance(currentMonthDate.year(), currentMonthDate.month(), day);
                                                
                        string BillStage= 'Draft';
                        if(billDate <= System.today()){
                            BillStage = 'Actual';
                        }
                        Decimal amount = 0;
                        if(acc.Rent_Type__c == 'Lumpsum' &&  acc.Rent_Amount__c != null ){
                            amount = acc.Rent_Amount__c;
                            
                        }else if(acc.Rent_Type__c == 'PSF' &&  acc.Tenant_Carpet__c != null && acc.Rent_Amount__c != null){
                            amount= (acc.Tenant_Carpet__c*acc.Rent_Amount__c).setScale(2,RoundingMODE.HALF_UP);
                        }
                        if(tenantEscalations != null ){
                            for(Escalation__c esc :tenantEscalations){
                                if(billDate>=esc.Start_Date__c && billDate <= esc.End_Date__c && esc.Escalation__c !=null){
                                    amount+= (amount * esc.Escalation__c / 100).setScale(2, RoundingMode.HALF_UP);
                                }
                            }
                        }

                        system.debug('Rent billDate'+billDate);
                        Bill__c rentalBill = new Bill__c(
                            Charge_Name__c= 'Rental Charges',
                        Tenant__c = acc.id,
                        Bill_Date__c = billDate,
                        Bill_Stage__c = BillStage,
                        Amount__c = amount,
                        Due_Date__c = billDate.addDays(ThresholdMap.get('Rent Threshold')),
                        Term_Sheet__c = termsheetId
                        );
                        
                        String draftBillHash = getHash(rentalBill);
                        if(!hashesForBillsByTenantID.containsKey(acc.Id) || !hashesForBillsByTenantID.get(acc.Id).contains(draftBillHash)){
                            draftBillsToInsert.add(rentalBill);
                        }

                        if(System.Today()>StartDate){
                            i++;
                        }
                    }
                    
                }
                
            }
            
            
            ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
            
            Bill__c transportDraftBill = new Bill__c();
            // Transport draft bills
            if(acc.Transport_Rent_Eligibility__c != Null &&  acc.Transport_Rent_Type__c != null && acc.Transport_Rent_Frequency__c != null && acc.Transport_Rent_Eligibility__c == 'Yes'){
                //for OneTime
                if(acc.Transport_Rent_Frequency__c == 'Onetime' &&  acc.Transport_Rent_Specific_Date__c != null){
                    if(EndDate >= acc.Transport_Rent_Specific_Date__c && acc.Transport_Rent_Specific_Date__c >= StartDate)
                        transportDraftBill.Bill_Date__c = acc.Transport_Rent_Specific_Date__c;
                    if(acc.Transport_Rent_Type__c == 'Lumpsum' &&  acc.Transport_Rent_Amount__c != null ){
                        transportDraftBill.Amount__c = acc.Transport_Rent_Amount__c;
                        
                    }else if(acc.Transport_Rent_Type__c == 'PSF' &&  acc.Tenant_Carpet__c != null && acc.Transport_Rent_Rate__c != null){
                        transportDraftBill.Amount__c = (acc.Tenant_Carpet__c*acc.Transport_Rent_Rate__c).setScale(2,RoundingMODE.HALF_UP);
                    }
                    if(acc.Actual_Transport_Rent_Paid__c !=null && acc.Actual_Transport_Rent_Paid__c >0){
                        transportDraftBill.Paid__c =  acc.Actual_Transport_Rent_Paid__c;
                    }
                
                    transportDraftBill.Charge_Name__c= 'Transport charges';
                    transportDraftBill.Tenant__c = acc.id;
                    transportDraftBill.Term_Sheet__c = termsheetId;
                    transportDraftBill.Due_Date__c = transportDraftBill.Bill_Date__c.addDays(ThresholdMap.get('Transport Threshold'));
                    transportDraftBill.Bill_Stage__c = 'Draft';
                    if(transportDraftBill.Bill_Date__c<=System.Today())
                        transportDraftBill.Bill_Stage__c = 'Actual';
                    
                    
                    String draftBillHash = getHash(transportDraftBill);
                    if(!hashesForBillsByTenantID.containsKey(acc.Id) || !hashesForBillsByTenantID.get(acc.Id).contains(draftBillHash)){
                        draftBillsToInsert.add(transportDraftBill);
                    }
    
    
                }else if(acc.Transport_Rent_Frequency__c == 'Monthly' &&  acc.Transport_Rent_Payment_time__c != null){
                    Integer noOfDraftBiilsToCreate = getNumberOfMonths(startDate, EndDate, acc.Transport_Rent_Payment_time__c );
                    
                    for(Integer i=1; i<= noOfDraftBiilsToCreate; i++){
                        system.debug('i '+i);
                        if(System.Today()>StartDate){
                            i--;
                        }
                        Date currentMonthDate = startDate.addMonths(i); // Increment by i months
                        Date billDate = null;
                        
                        if (acc.Transport_Rent_Payment_time__c == 'Start of Month') {
                            billDate = Date.newInstance(currentMonthDate.year(), currentMonthDate.month(), 1);
                        }
                        else if (acc.Transport_Rent_Payment_time__c == 'Middle of Month') {
                            billDate = Date.newInstance(currentMonthDate.year(), currentMonthDate.month(), 15);
                        }
                        else if (acc.Transport_Rent_Payment_time__c == 'End of Month') {
                            Integer lastDay = Date.daysInMonth(currentMonthDate.year(), currentMonthDate.month());
                            billDate = Date.newInstance(currentMonthDate.year(), currentMonthDate.month(), lastDay);
                        }
                        else if (acc.Transport_Rent_Payment_time__c == 'Specific date in Month') {
                            Integer day = acc.Rent_Specific_Date__c.day();
                            billDate = Date.newInstance(currentMonthDate.year(), currentMonthDate.month(), day);
                        }
                        
                        String BillStage= 'Draft';
                        if(billDate <= System.today()){
                            BillStage = 'Actual';
                        }
                        Decimal amount =0;
                        if(acc.Transport_Rent_Type__c == 'Lumpsum' &&  acc.Transport_Rent_Amount__c != null ){
                            amount = acc.Transport_Rent_Amount__c;
                            
                        }else if(acc.Transport_Rent_Type__c == 'PSF' &&  acc.Tenant_Carpet__c != null && acc.Transport_Rent_Rate__c != null){
                            amount = (acc.Tenant_Carpet__c*acc.Transport_Rent_Rate__c).setScale(2,RoundingMODE.HALF_UP);
                        }
                        
                        Bill__c transportBill = new Bill__c(
                            Charge_Name__c= 'Transport charges',
                            Tenant__c = acc.id,
                            Bill_Date__c = billDate,
                            Bill_Stage__c = BillStage,
                            Term_Sheet__c = termsheetId,
                            Amount__c = amount,
                            Due_Date__c =billDate.addDays(ThresholdMap.get('Transport Threshold'))
                        );

                        String draftBillHash = getHash(transportBill);
                        if(!hashesForBillsByTenantID.containsKey(acc.Id) || !hashesForBillsByTenantID.get(acc.Id).contains(draftBillHash)){
                            draftBillsToInsert.add(transportBill);
                        }


                        if(System.Today()>StartDate){
                            i++;
                        }
                    }
                    
                }
                
            }
            
            // Brokerage draft bills
            if(acc.Brokerage_Frequency__c != null && acc.Brokerage_Eligibility__c != null && acc.Brokerage_Eligibility__c=='Yes'){
                if (acc.Brokerage_Frequency__c == 'Yearly' || acc.Brokerage_Frequency__c == 'Half Yearly') {
                    Date currentBillDate =null;
                    if(StartDate<System.Today()){
                        currentBillDate= System.Today();
                    } else if(System.Today()<StartDate){
                        currentBillDate= StartDate;
                    }
                    
                    Date overallEndDate = EndDate;
                    Integer incrementMonths;
                    
                    if (acc.Brokerage_Frequency__c == 'Yearly') {
                        incrementMonths = 12; // 1 year interval

                        if( acc.Brokerage_Payment_Time__c != null && 
                            acc.Brokerage_Payment_Time__c == 'Specific Date of the year' &&
                            acc.Brokerage_Specific_Date__c != null){
                                currentBillDate = Date.newInstance(currentBillDate.year(), acc.Brokerage_Specific_Date__c.month(), acc.Brokerage_Specific_Date__c.day());
                        }
                        if( acc.Brokerage_Payment_Time__c != null && 
                            acc.Brokerage_Payment_Time__c == 'Specific Date' &&
                            acc.Brokerage_Specific_Date__c != null){
                                currentBillDate = Date.newInstance(currentBillDate.year(), currentBillDate.month(), acc.Brokerage_Specific_Date__c.day());
                        }
                    } else if (acc.Brokerage_Frequency__c == 'Half Yearly') {
                        incrementMonths = 6; // 6 months interval
                        if( acc.Brokerage_Payment_Time__c != null && 
                            acc.Brokerage_Payment_Time__c == 'Specific Date' &&
                            acc.Brokerage_Specific_Date__c != null){
                                currentBillDate = Date.newInstance(currentBillDate.year(), currentBillDate.month(), acc.Brokerage_Specific_Date__c.day());
                        }
                    } else {
                        continue;
                    }
                    
                    string BillStage= 'Draft';
                    if(currentBillDate < System.today()){
                        BillStage = 'Actual';
                    }

                    // Generate draft bills
                    while (currentBillDate <= overallEndDate){
                        // Initialize a new draft bill
                        Bill__c brokerageDraftBill = new Bill__c();
                        
                        brokerageDraftBill.Bill_Date__c = currentBillDate;
                        brokerageDraftBill.Due_Date__c = currentBillDate.addDays(ThresholdMap.get('Brokerage Threshold'));
                        brokerageDraftBill.Charge_Name__c = 'Brokerage';
                        brokerageDraftBill.Tenant__c = acc.Id;
                        brokerageDraftBill.Term_Sheet__c = termsheetId;
                        brokerageDraftBill.Bill_Stage__c = BillStage;
                        if(acc.Brokerage_Type__c == 'Lumpsum' &&  acc.Brokerage_Amount__c != null ){
                            brokerageDraftBill.Amount__c = acc.Brokerage_Amount__c; // Assuming amount is constant
                            
                        }else if(acc.Brokerage_Type__c == 'PSF' &&  acc.Tenant_Carpet__c != null && acc.Brokerage_Amount__c != null){
                            brokerageDraftBill.Amount__c = (acc.Tenant_Carpet__c*acc.Brokerage_Amount__c).setScale(2,RoundingMODE.HALF_UP);
                        }
                        
                        // Add the draft bill to the list
                        String draftBillHash = getHash(brokerageDraftBill);
                        if(!hashesForBillsByTenantID.containsKey(acc.Id) || !hashesForBillsByTenantID.get(acc.Id).contains(draftBillHash)){
                            draftBillsToInsert.add(brokerageDraftBill);
                        }

                        
                        // Increment the bill date based on frequency
                        currentBillDate = currentBillDate.addMonths(incrementMonths);
                    }
                }
                if (acc.Brokerage_Frequency__c == 'Onetime') {

                    Bill__c brokerageDraftBill = new Bill__c();

                    Date currentBillDate = StartDate;
                    if (acc.Brokerage_Payment_Time__c == 'Specific Date' &&
                        acc.Brokerage_Specific_Date__c != null && EndDate >= acc.Brokerage_Specific_Date__c &&
                        acc.Brokerage_Specific_Date__c >= StartDate) {
                        currentBillDate = acc.Brokerage_Specific_Date__c;
                    }

                    if(acc.Brokerage_Type__c == 'Lumpsum' &&  acc.Brokerage_Amount__c != null ){
                        brokerageDraftBill.Amount__c = acc.Brokerage_Amount__c;
                    }else if(acc.Brokerage_Type__c == 'PSF' &&  acc.Tenant_Carpet__c != null && acc.Brokerage_Rate__c != null){
                        brokerageDraftBill.Amount__c = (acc.Tenant_Carpet__c*acc.Brokerage_Rate__c).setScale(2,RoundingMODE.HALF_UP);
                    }
                    if(acc.Actual_Brokerage_Paid__c != null && acc.Actual_Brokerage_Paid__c >0){
                        brokerageDraftBill.Paid__c =  acc.Actual_Brokerage_Paid__c;
                    }


                    brokerageDraftBill.Bill_Date__c = currentBillDate;
                    brokerageDraftBill.Charge_Name__c= 'Brokerage';
                    brokerageDraftBill.Tenant__c = acc.id;
                    brokerageDraftBill.Term_Sheet__c = termsheetId;
                    brokerageDraftBill.Bill_Stage__c = 'Draft';
                    if(brokerageDraftBill.Bill_Date__c<=System.Today())
                        brokerageDraftBill.Bill_Stage__c = 'Actual';
    
                    
                    String draftBillHash = getHash(brokerageDraftBill);
                    if(!hashesForBillsByTenantID.containsKey(acc.Id) || !hashesForBillsByTenantID.get(acc.Id).contains(draftBillHash)){
                        draftBillsToInsert.add(brokerageDraftBill);
                    }
    
                    
                }
                
                
            }
            Bill__c miscDraftBill = new Bill__c();
            // Misc draft bills
            if(acc.MISC_Eligibility__c != Null &&  acc.MISC_Type__c != null && acc.MISC_Frequency__c != null && acc.MISC_Eligibility__c == 'Yes'){
                if(acc.MISC_Frequency__c == 'Onetime' &&  acc.MISC_Specific_Date__c != null){
                    if(EndDate >= acc.MISC_Specific_Date__c && acc.MISC_Specific_Date__c >= StartDate)
                        miscDraftBill.Bill_Date__c = acc.MISC_Specific_Date__c;
                    
                    if(acc.MISC_Type__c == 'Lumpsum' &&  acc.MISC_Amount__c != null ){
                        miscDraftBill.Amount__c = acc.MISC_Amount__c;
                        
                    }else if(acc.MISC_Type__c == 'PSF' &&  acc.Tenant_Carpet__c != null && acc.MISC_Rate__c != null){
                        miscDraftBill.Amount__c = (acc.Tenant_Carpet__c*acc.MISC_Rate__c).setScale(2,RoundingMODE.HALF_UP);
                    }
                    if(acc.Actual_MISC_Paid__c !=null && acc.Actual_MISC_Paid__c >0){
                        miscDraftBill.Paid__c =  acc.Actual_MISC_Paid__c;
                    }
                    miscDraftBill.Charge_Name__c= 'Misc/Other';
                    miscDraftBill.Tenant__c = acc.id;
                    miscDraftBill.Term_Sheet__c = termsheetId;
                    miscDraftBill.Bill_Stage__c = 'Draft';
                    miscDraftBill.Due_Date__c = miscDraftBill.Bill_Date__c.addDays(ThresholdMap.get('MISC Threshold'));


                    String draftBillHash = getHash(miscDraftBill);
                    System.debug('miscDraftBill hash : ' + draftBillHash);

                    if(!hashesForBillsByTenantID.containsKey(acc.Id) || !hashesForBillsByTenantID.get(acc.Id).contains(draftBillHash)){
                        draftBillsToInsert.add(miscDraftBill);
                    }
                    
                }
                else if(acc.MISC_Frequency__c == 'Monthly' &&  acc.MISC_Payment_time__c != null && acc.MISC_Payment_time__c != 'Specific date in Month'){
                    Integer noOfDraftBiilsToCreate = getNumberOfMonths(startDate, EndDate, acc.MISC_Payment_time__c);
                    
                    for(Integer i=1; i<= noOfDraftBiilsToCreate; i++){
                        system.debug('i '+i);
                        if(System.Today()>StartDate){
                            i--;
                        }
                        Date currentMonthDate = startDate.addMonths(i); // Increment by i months
                        Date billDate = null;
                        
                        if (acc.MISC_Payment_time__c == 'Start of Month') {
                            billDate = Date.newInstance(currentMonthDate.year(), currentMonthDate.month(), 1);
                        }
                        else if (acc.MISC_Payment_time__c == 'Middle of Month') {
                            billDate = Date.newInstance(currentMonthDate.year(), currentMonthDate.month(), 15);
                        }
                        else if (acc.MISC_Payment_time__c == 'End of Month'){
                            Integer lastDay = Date.daysInMonth(currentMonthDate.year(), currentMonthDate.month());
                            billDate = Date.newInstance(currentMonthDate.year(), currentMonthDate.month(), lastDay);
                        }
                        
                        string BillStage= 'Draft';
                        if(billDate < System.today()){
                            BillStage = 'Actual';
                        }
                        Decimal Amount = 0;
                        if(acc.MISC_Type__c == 'Lumpsum' &&  acc.MISC_Amount__c != null ){
                            Amount = acc.MISC_Amount__c;
                            
                        }else if(acc.MISC_Type__c == 'PSF' &&  acc.Tenant_Carpet__c != null && acc.MISC_Rate__c != null){
                            Amount = (acc.Tenant_Carpet__c*acc.MISC_Rate__c).setScale(2,RoundingMODE.HALF_UP);
                        }
                        
                        Bill__c miscBill =  new Bill__c(
                            Charge_Name__c= 'Misc/Other',
                            Tenant__c = acc.id,
                            Bill_Date__c = billDate,
                            Bill_Stage__c = BillStage,
                            Amount__c = Amount,
                            Term_Sheet__c = termsheetId,
                            Due_Date__c = billDate.addDays(ThresholdMap.get('MISC Threshold'))    
                        );

                        String draftBillHash = getHash(miscBill);
                        System.debug('miscDraftBill hash : ' + draftBillHash);

                        if(!hashesForBillsByTenantID.containsKey(acc.Id) || !hashesForBillsByTenantID.get(acc.Id).contains(draftBillHash)){
                            draftBillsToInsert.add(miscBill);
                        }


                        if(System.Today()>StartDate){
                            i++;
                        }
                    }
                    
                }
                
            }
            
            // Corpurus  draft bills
            
            for (Integer i = 1; i <= 5; i++) {
                Bill__c corpusDraftBill = new Bill__c();
                if ((String) acc.get('Corpus_' + i + '_Eligibility__c') != null && (String) acc.get('Corpus_' + i + '_Eligibility__c')=='Yes') {
                    if(((String) acc.get('Corpus_' + i + '_Frequency__c'))  != null && (String) acc.get('Corpus_' + i + '_Frequency__c') == 'Onetime' && (Date) acc.get('Corpus_' + i + '_Specific_Date__c')!=null){
                        Date specificDate =(Date) acc.get('Corpus_' + i + '_Specific_Date__c');
                        if(EndDate >= specificDate && specificDate >= StartDate)
                            corpusDraftBill.Bill_Date__c = (Date) acc.get('Corpus_' + i + '_Specific_Date__c');
                        
                        
                        if(((String) acc.get('Corpus_' + i + '_Type__c'))  != null && (String) acc.get('Corpus_' + i + '_Type__c') == 'Lumpsum' && acc.get('Corpus_' + i + '_Amount__c')!=null && ((Decimal) acc.get('Corpus_' + i + '_Amount__c'))>0){
                            
                            corpusDraftBill.Amount__c = ((Decimal) acc.get('Corpus_' + i + '_Amount__c'));
                            
                        }else if(((String) acc.get('Corpus_' + i + '_Type__c'))  != null && (String) acc.get('Corpus_' + i + '_Type__c') == 'PSF' &&  acc.get('Corpus_' + i + '_Rate__c') !=null   && (Decimal) acc.get('Corpus_' + i + '_Rate__c')> 0 && acc.Tenant_Carpet__c>0 ){
                            
                            corpusDraftBill.Amount__c = (acc.Tenant_Carpet__c*((Decimal) acc.get('Corpus_' + i + '_Rate__c'))).setScale(2,RoundingMODE.HALF_UP);
                            
                        }
                        
                        if((acc.get('Actual_Corpus_' + i + '_Paid__c'))  != null && (Decimal) acc.get('Actual_Corpus_' + i + '_Paid__c') >0){
                            
                            corpusDraftBill.Paid__c = ((Decimal) acc.get('Actual_Corpus_' + i + '_Paid__c'));
                            
                        }
                        
                        corpusDraftBill.Charge_Name__c= string.valueOf('Corpus Fund '+i);
                        corpusDraftBill.Tenant__c = acc.id;
                        corpusDraftBill.Term_Sheet__c = termsheetId;
                        corpusDraftBill.Bill_Stage__c = 'Draft';
                        corpusDraftBill.Due_Date__c=   corpusDraftBill.Bill_Date__c.addDays(ThresholdMap.get('Corpus Threshold'));
                        
                        String draftBillHash = getHash(corpusDraftBill);
                        if(!hashesForBillsByTenantID.containsKey(acc.Id) || !hashesForBillsByTenantID.get(acc.Id).contains(draftBillHash)){
                            draftBillsToInsert.add(corpusDraftBill);
                        }

                    }else if(((String) acc.get('Corpus_' + i + '_Frequency__c'))  != null && (String) acc.get('Corpus_' + i + '_Frequency__c') == 'Monthly' &&  acc.get('Corpus_' + i + '_Payment_Time__c')!=null && String.valueOf(acc.get('Corpus_' + i + '_Payment_Time__c'))!='Specific date in Month'){
                        
                        Integer noOfDraftBiilsToCreate = getNumberOfMonths(startDate, EndDate, acc.MISC_Payment_time__c);
                        
                        for(Integer j=1; j<= noOfDraftBiilsToCreate; j++){
                            system.debug('j '+j);
                            if(System.Today()>StartDate){
                                j--;
                            }
                            Date currentMonthDate = startDate.addMonths(j); // Increment by i months
                            Date billDate = null;
                            
                            if (String.valueOf(acc.get('Corpus_' + i + '_Payment_Time__c'))== 'Start of Month') {
                                billDate = Date.newInstance(currentMonthDate.year(), currentMonthDate.month(), 1);
                            }
                            else if (String.valueOf(acc.get('Corpus_' + i + '_Payment_Time__c')) == 'Middle of Month') {
                                billDate = Date.newInstance(currentMonthDate.year(), currentMonthDate.month(), 15);
                            }
                            else if (String.valueOf(acc.get('Corpus_' + i + '_Payment_Time__c')) == 'End of Month'){
                                Integer lastDay = Date.daysInMonth(currentMonthDate.year(), currentMonthDate.month());
                                billDate = Date.newInstance(currentMonthDate.year(), currentMonthDate.month(), lastDay);
                            }
                            
                            string BillStage= 'Draft';
                            if(billDate < System.today()){
                                BillStage = 'Actual';
                            }
                            Decimal Amount = 0;
                            if(((String) acc.get('Corpus_' + i + '_Type__c'))  != null && (String) acc.get('Corpus_' + i + '_Type__c') == 'Lumpsum' && acc.get('Corpus_' + i + '_Amount__c')!=null && ((Decimal) acc.get('Corpus_' + i + '_Amount__c'))>0){
                                
                                Amount = ((Decimal) acc.get('Corpus_' + i + '_Amount__c'));
                                
                            }else if(((String) acc.get('Corpus_' + i + '_Type__c'))  != null && (String) acc.get('Corpus_' + i + '_Type__c') == 'PSF' &&  acc.get('Corpus_' + i + '_Rate__c') !=null   && (Decimal) acc.get('Corpus_' + i + '_Rate__c')> 0 && acc.Tenant_Carpet__c>0 ){
                                
                                Amount = (acc.Tenant_Carpet__c*((Decimal) acc.get('Corpus_' + i + '_Rate__c'))).setScale(2,RoundingMODE.HALF_UP);
                                
                            }
                            Bill__c corpusFundBill = new Bill__c(
                                Charge_Name__c= string.valueOf('Corpus Fund '+i),
                                Tenant__c = acc.id,
                                Bill_Date__c = billDate,
                                Bill_Stage__c = BillStage,
                                Amount__c = Amount,
                                Due_Date__c = billDate.addDays(ThresholdMap.get('Corpus Threshold'))    
                            );

                            String draftBillHash = getHash(corpusFundBill);
                            if(!hashesForBillsByTenantID.containsKey(acc.Id) || !hashesForBillsByTenantID.get(acc.Id).contains(draftBillHash)){
                                draftBillsToInsert.add(corpusFundBill);
                            }

                            
                            if(System.Today()>StartDate){
                                j++;
                            }
                        }
                        
                        
                    }
                    System.debug('corpusDraftBill '+draftBillsToInsert);
                }
            }
            
        }
        
        //Insert all draft bills
        if(draftBillsToInsert != null && draftBillsToInsert.size()>0){
            List<Database.SaveResult> saveResults = Database.insert(draftBillsToInsert, false);
            
            Boolean allSuccessful = true;
            
            
            for (Database.SaveResult saveResult : saveResults) {
                if (!saveResult.isSuccess()) {
                    allSuccessful = false;
                    System.debug('Insert failed for record: ' + saveResult.getErrors());
                }
            }
            if(allSuccessful){
                Term_Sheet__c tr = new Term_Sheet__c(Id=termsheetId, Is_Draft_Bill_Generated__c = true);
                update(tr);
            }
        }

        System.debug('heapsize 5: ' + Limits.getHeapSize());
        
        
    }

    // Create Draft Bill "Excess Carpet Area"
    public static void createBillForExcessCarpetArea(Id tenandId, Date billDate, Decimal amount){

        String CHARGE_NAME = 'Excess Carpet Area';
        Integer THRESHOLD_DAYS = 7;

        Bill__c excessCarpetAreaBill = new Bill__c();

        excessCarpetAreaBill.Charge_Name__c = CHARGE_NAME;
        excessCarpetAreaBill.Amount__c = amount;
        excessCarpetAreaBill.Bill_Date__c = billDate;
        excessCarpetAreaBill.Tenant__c = tenandId;
        excessCarpetAreaBill.Bill_Stage__c = 'Draft';
        excessCarpetAreaBill.Due_Date__c = billDate.addDays(THRESHOLD_DAYS);

        INSERT excessCarpetAreaBill;
    }

    
    //Method to retunr No of Months
    public static Integer getNumberOfMonths(Date StartDate , Date EndDate, String paymentType){
        
        if (StartDate != null && EndDate != null && paymentType != null) {
            
            Integer totalMonths = ((EndDate.year() - StartDate.year()) * 12) + (EndDate.month() - StartDate.month()) + 1;
            
            if (paymentType == 'Start of Month'){
                return totalMonths;
            } else if (paymentType == 'Middle of Month') {
                // Adjust if StartDate or EndDate doesn't include the 15th
                if (StartDate.day() > 15) {
                    totalMonths--;
                }
                if (EndDate.day() < 15) {
                    totalMonths--;
                }
                return totalMonths;
            } else if (paymentType == 'End of Month') {
                // Adjust if StartDate or EndDate is not the last day of the month
                //  if (StartDate.day() != Date.daysInMonth(StartDate.year(), StartDate.month())) {
                //     totalMonths--;
                // }
                // if (EndDate.day() != Date.daysInMonth(EndDate.year(), EndDate.month())) {
                //     totalMonths--;
                // }
                return totalMonths;
            }

            return totalMonths;
        }
        return 0;
        
    }
    
    public static Map<Id,List<Escalation__c>> getEscallationsWithTenatId(List<Account>Tenants){
        Map<Id,List<Escalation__c>> EscallationsWithTenatId = new Map<Id,List<Escalation__c>>();
        List<Escalation__c>Escallations = [Select Id , Name ,Start_Date__c, END_Date__c , Escalation__c, Tenant__c 
                                           From Escalation__c Where Tenant__c IN:Tenants AND Start_Date__c !=null AND END_Date__c!=null ];
        for(Escalation__c e:Escallations ){
            if(EscallationsWithTenatId.containsKey(e.Tenant__c))
                EscallationsWithTenatId.get(e.Tenant__c).add(e);
            else{
                EscallationsWithTenatId.put(e.Tenant__c,new List<Escalation__c>{e});
            }
        }
        if(EscallationsWithTenatId != null && EscallationsWithTenatId.size()>0)
            return EscallationsWithTenatId;
        else return null;
    }


    public static Map<Id, Set<String>> getHashesForTenantBills(Set<Id> tenantAccountIDs, Id termsSheetID){

        System.debug('heapsize 2: ' + Limits.getHeapSize());

        Map<Id, Set<String>> billRecordHashesByAccount = new Map<Id, Set<String>>();

        List<Bill__c> bills = [SELECT Id, Name, Bill_Date__c, Tenant__c, Term_Sheet__c, Charge_Name__c
                               FROM Bill__c
                               WHERE Tenant__c IN :tenantAccountIDs AND
                                     Term_Sheet__c = :termsSheetID AND 
                                     Bill_Date__c != null AND
                                     Tenant__c != null];

        for (Bill__c bill : bills) {

            String currentBillHash = getHash(bill.Bill_Date__c, bill.Charge_Name__c,
                                             bill.Tenant__c, bill.Term_Sheet__c);
            System.debug('exsiting currentBillHash : ' + currentBillHash);
            String key = bill.Tenant__c;
            if(!billRecordHashesByAccount.containsKey(key)){
                billRecordHashesByAccount.put(key, new Set<String>{});
            }
            billRecordHashesByAccount.get(key).add(currentBillHash);
            
        }

        System.debug('heapsize 3: ' + Limits.getHeapSize());


        return billRecordHashesByAccount;
    }

    // Generate as Unique value for Provided Data
    public static String getHash(Date billDate, String chargeName, String tenantId, String termSheetID){

        String combinedInput = billDate.format() + chargeName + tenantId + termSheetID;
        Blob inputBlob = Blob.valueOf(combinedInput);
        Blob hashBlob = Crypto.generateDigest('SHA-256', inputBlob);
        String hash = EncodingUtil.convertToHex(hashBlob);

        System.debug('combinedInput: ' + combinedInput);
        System.debug('hash: ' + hash);
        return combinedInput;
    }

    // Overloaded Method for original method
    public static String getHash(Bill__c bill){
        Date billDate = bill.Bill_Date__c;
        String chargeName = bill.Charge_Name__c;
        String tenantId = bill.Tenant__c;
        String termSheetID = bill.Term_Sheet__c;

        return getHash(billDate, chargeName, tenantId, termSheetID);
    }

}