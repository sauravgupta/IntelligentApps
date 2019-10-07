Class Demo.Messages.RegistryLookupResponse Extends Ens.Response
{

Property PatientInfo As PatientInfo;

Property PrescriberInfo As PrescriberInfo;

Storage Default
{
<Data name="RegistryLookupResponseDefaultData">
<Subscript>"RegistryLookupResponse"</Subscript>
<Value name="1">
<Value>PatientInfo</Value>
</Value>
<Value name="2">
<Value>PrescriberInfo</Value>
</Value>
</Data>
<DefaultData>RegistryLookupResponseDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}

