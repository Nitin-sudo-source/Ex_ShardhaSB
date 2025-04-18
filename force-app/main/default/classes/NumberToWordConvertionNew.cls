/**
 * @description This class is used to convert number into words 
 */
public class NumberToWordConvertionNew {
    /**
     * @description This is invocable method to convert number into words 
     * @param requestList
     * @return String 
     */
    @InvocableMethod(label ='Number To Word Convertion New' description='Number To Word Convertion')
    public static List<String> execute(List<Decimal> requestList){
        List<String> amountInWordsList = new List<String>();
        if(!requestList.isEmpty()){
            for(Decimal req: requestList){
                String amountInWords;
                amountInWords = NumberToWordConvertionNew.getNumberTOWordConvertion(req);
                amountInWordsList.add(amountInWords);
            }
        }
        return amountInWordsList;
    }
    
    /**
     * @description This is helper method to convert number into words 
     * @param num
     * @return String 
     */
    public static String getNumberTOWordConvertion(Decimal num) {
        Decimal junkVal = num;
        Decimal junkValPaisa = junkVal - Math.floor(junkVal);
        junkVal = Math.floor(junkVal);
        String obStr = junkVal.toPlainString();
        String[] numReversed = obStr.split('');
        String[] actnumber = reverse(numReversed);
        String firstHalf = convertInWords(numReversed, actnumber);
        Integer tmp = Math.round(junkValPaisa * 100);
        junkValPaisa = (Decimal)tmp / 100;
        String paisaStr = junkValPaisa.toPlainString();
        String secondHalf;
        if (paisaStr == '0') {
            secondHalf = '';
        } else if (paisaStr.length() != 4) {
            paisaStr = paisaStr + '0';
            paisaStr = paisaStr.substring(2);
            String [] numReversedPaisa = paisaStr.split('');
            String[] actnumberPaisa = reverse(numReversedPaisa);
            secondHalf = convertInWords(numReversedPaisa, actnumberPaisa);
        } else {
            paisaStr = paisaStr.substring(2);
            String [] numReversedPaisa = paisaStr.split('');
            String[] actnumberPaisa = reverse(numReversedPaisa);
            secondHalf = convertInWords(numReversedPaisa, actnumberPaisa);
        }
        String sumOFHalves = '';
        if (secondHalf.length() > 4) {
            //firstHalf = firstHalf.replace('Only', 'Rupess And ');
            //secondHalf = secondHalf.replace('Only', 'Paisa Only');
            firstHalf = firstHalf.replace('Only', '');
            secondHalf = secondHalf.replace('Only', '');
            sumOFHalves = firstHalf + secondHalf;
        } else {
            //firstHalf = firstHalf.replace('Only', 'Rupess Only');
            firstHalf = firstHalf.replace('Only', '');
            sumOFHalves = firstHalf;
        }
        // IF amount has any value
        if (sumOFHalves.length() > 5) {
            return sumOFHalves;
        } else {
            return '';
        }
    }

    /**
     * @description This is method to reverse the string
     * @param strToRev
     * @return lsit of String 
     */
    public static List<String> reverse(List<String> strToRev) {
        List<String> revList = new List<String>();
        for (Integer i = strToRev.size() - 1; i >= 0; i--) {
            revList.add(strToRev.get(i));
        }
        revList.add('');
        return revList;
    }

    /**
     * @description This is method to convert number into words 
     * @param numRev
     * @param actnum
     * @return String 
     */
    public static String convertInWords(String[] numRev, String[] actnum) {
        List<String> iWords = new List<String> {'Zero', ' One', ' Two', ' Three', ' Four', ' Five', ' Six', ' Seven', ' Eight', ' Nine'};
        List<String> ePlace = new List<String> {' Ten', ' Eleven', ' Twelve', ' Thirteen', ' Fourteen', ' Fifteen', ' Sixteen', ' Seventeen', ' Eighteen', ' Nineteen'};
        List<String> tensPlace = new List<String> {'dummy', ' Ten', ' Twenty', ' Thirty', ' Forty', ' Fifty', ' Sixty', ' Seventy', ' Eighty', ' Ninety' };
        Integer iWordsLength = numRev.size();

        List<String> inWords = new List<String>();
        for (Integer k = 0; k < iWordsLength; k++) {
            inWords.add('');
        }
        String finalWord = '';
        Integer j = 0;
        // Main For loop
        for (Integer i = 0; i < iWordsLength; i++) {
            if (i == 0) {
                if (actnum[i] == '0' || actnum[i + 1] == '1') {
                    inWords[j] = '';
                } else {
                    inWords[j] = iWords[Integer.valueof(actnum[i])];
                }
                inWords[j] = inWords[j] + ' Only';
            } else if (i == 1) {
                if (actnum[i] == '0') {
                    inWords[j] = '';
                } else if (actnum[i] == '1') {
                    inWords[j] = ePlace[Integer.valueof(actnum[i - 1])];
                } else {
                    inWords[j] = tensPlace[Integer.valueof(actnum[i])];
                }
            } else if (i == 2) {
                if (actnum[i] == '0') {
                    inWords[j] = '';
                } else if (actnum[i - 1] != '0' && actnum[i - 2] != '0') {
                    inWords[j] = iWords[Integer.valueof(actnum[i])] + ' Hundred and';
                } else {
                    inWords[j] = iWords[Integer.valueof(actnum[i])] + ' Hundred';
                }
            } else if (i == 3) {
                if (actnum[i] == '0' || actnum[i + 1] == '1') {
                    inWords[j] = '';
                } else {
                    inWords[j] = iWords[Integer.valueof(actnum[i])];
                }
                if (actnum[i + 1] != '0' || Integer.valueof(actnum[i]) > 0) {
                    inWords[j] = inWords[j] + ' Thousand';
                }
            } else if (i == 4) {
                if (actnum[i] == '0') {
                    inWords[j] = '';
                } else if (actnum[i] == '1') {
                    inWords[j] = ePlace[Integer.valueof(actnum[i - 1])];
                } else {
                    inWords[j] = tensPlace[Integer.valueof(actnum[i])];
                }
            } else if (i == 5) {
                if (actnum[i] == '0' || actnum[i + 1] == '1') {
                    inWords[j] = '';
                } else {
                    inWords[j] = iWords[Integer.valueof(actnum[i])];
                }
                if (actnum[i + 1] != '0' || Integer.valueof(actnum[i]) > 0) {
                    inWords[j] = inWords[j] + ' Lakh';
                }
            } else if (i == 6) {
                if (actnum[i] == '0') {
                    inWords[j] = '';
                } else if (actnum[i] == '1') {
                    inWords[j] = ePlace[Integer.valueof(actnum[i - 1])];
                } else {
                    inWords[j] = tensPlace[Integer.valueof(actnum[i])];
                }
            } else if (i == 7) {
                if (actnum[i] == '0' || actnum[i + 1] == '1' ) {
                    inWords[j] = '';
                } else {
                    inWords[j] = iWords[Integer.valueof(actnum[i])];
                }
                inWords[j] = inWords[j] + ' Crore';
            } else if (i == 8) {
                if (actnum[i] == '0') {
                    inWords[j] = '';
                } else if (actnum[i] == '1') {
                    inWords[j] = ePlace[Integer.valueof(actnum[i - 1])];
                } else {
                    inWords[j] = tensPlace[Integer.valueof(actnum[i])];
                }
            }
            j++;
        }
        
        inWords = reverse(inWords);
        for (Integer i = 0; i < inWords.size(); i++) {
            finalWord += inWords[i];
        }
        return finalWord;
    }
}