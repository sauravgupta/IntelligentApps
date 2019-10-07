Class Demo.Messages.RegistryLookupRequest Extends Ens.Request
{

Property PatientEMail As %String(MAXLEN = 500);

Property PatientID As %String(MAXLEN = 100);

Property PrescriberID As %String;

Storage Default
{
<Data name="RegistryLookupRequestDefaultData">
<Subscript>"RegistryLookupRequest"</Subscript>
<Value name="1">
<Value>PatientID</Value>
</Value>
<Value name="2">
<Value>PrescriberID</Value>
</Value>
<Value name="3">
<Value>PatientEMail</Value>
</Value>
</Data>
<DefaultData>RegistryLookupRequestDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}

