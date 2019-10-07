Class Demo.Messages.PatientInfo Extends (%SerialObject, %XML.Adaptor, %Populate)
{

Property PatientID As %String(MAXLEN = 100);

Property Name As %String(MAXLEN = 200);

Property DateOfBirth As %Date;

Property Gender As %String(VALUELIST = ",male,female");

Property MedicationHistory As array Of %String;

Method OnPopulate() As %Status
{
    do ..MedicationHistory.Clear()
    
    // we'll take 5-10 out of the 50 most common medications and assign
    // a count of 0-9 to them
    set tMeds = "Rx834060,Rx834101,Rx608680,Rx824184,Rx1736854,Rx313782,Rx564666,Rx310965,Rx849574,Rx583214,Rx309362,Rx727316,Rx1020137,Rx282464,Rx198405,Rx575971,Rx1803932,Rx896188,Rx849727,Rx312961,Rx197361,Rx392151,Rx860975,Rx745679,Rx895994,Rx904420,Rx1094108,Rx568530,Rx1049630,Rx665078,Rx861467,Rx757594,Rx106892,Rx1049221,Rx106258,Rx997488,Rx309097,Rx308192,Rx857005,Rx308056,Rx239981,Rx748962,Rx602735,Rx831533,Rx897122,Rx1000128,Rx1734340,Rx807283,Rx197378,Rx312617"
    set tMedCount = $l(tMeds,",")
    set tTakenCount = $random(5)+5
    for i = 1:1:tTakenCount {
	    set tTaken = $piece(tMeds,",",$random(tMedCount)), tFreq = $normalize(($random(99)/33)**2,0)
	    do ..MedicationHistory.SetAt(tFreq,tTaken)
    }
    quit $$$OK
}

Storage Default
{
<Data name="PatientInfoState">
<Value name="1">
<Value>PatientID</Value>
</Value>
<Value name="2">
<Value>Name</Value>
</Value>
<Value name="3">
<Value>DateOfBirth</Value>
</Value>
<Value name="4">
<Value>Gender</Value>
</Value>
<Value name="5">
<Value>MedicationHistory</Value>
</Value>
</Data>
<State>PatientInfoState</State>
<StreamLocation>^Demo.Messages.PatientInfoS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}

