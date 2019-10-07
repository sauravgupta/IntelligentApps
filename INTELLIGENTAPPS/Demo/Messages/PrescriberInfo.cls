Class Demo.Messages.PrescriberInfo Extends (%SerialObject, %XML.Adaptor, %Populate)
{

Property PrescriberID As %String(MAXLEN = 50);

Property Name As %String(MAXLEN = 200);

Property Specialty As %String(MAXLEN = 100);

Storage Default
{
<Data name="PrescriberInfoState">
<Value name="1">
<Value>PrescriberID</Value>
</Value>
<Value name="2">
<Value>Name</Value>
</Value>
<Value name="3">
<Value>Specialty</Value>
</Value>
</Data>
<State>PrescriberInfoState</State>
<StreamLocation>^Demo.Messages.PrescriberInfoS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}

