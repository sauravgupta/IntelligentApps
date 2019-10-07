Class Demo.BPL.ProcessContext Extends Ens.BP.Context
{

Property PatientInfo As Demo.Messages.PatientInfo;

Property PrescriberInfo As Demo.Messages.PrescriberInfo;

Storage Default
{
<Data name="ProcessContextDefaultData">
<Subscript>"ProcessContext"</Subscript>
<Value name="1">
<Value>PatientInfo</Value>
</Value>
<Value name="2">
<Value>PrescriberInfo</Value>
</Value>
</Data>
<DefaultData>ProcessContextDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}

