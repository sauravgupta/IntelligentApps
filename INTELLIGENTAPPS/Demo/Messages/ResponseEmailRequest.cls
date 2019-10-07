Class Demo.Messages.ResponseEmailRequest Extends Ens.Request
{

Property ToEMail As %String(MAXLEN = 500);

Property Subject As %String(MAXLEN = 500);

Property Message As %String(MAXLEN = "");

Property RequestStatus As %String(MAXLEN = 50);

Property OriginalDate As %String(MAXLEN = 200);

Property OriginalText As %String(MAXLEN = "");

Property InteractionInfo As DrugInteractionResponse;

Storage Default
{
<Data name="ResponseEmailRequestDefaultData">
<Subscript>"ResponseEmailRequest"</Subscript>
<Value name="1">
<Value>ToEMail</Value>
</Value>
<Value name="2">
<Value>Subject</Value>
</Value>
<Value name="3">
<Value>Message</Value>
</Value>
<Value name="4">
<Value>RequestStatus</Value>
</Value>
<Value name="5">
<Value>OriginalDate</Value>
</Value>
<Value name="6">
<Value>OriginalText</Value>
</Value>
<Value name="7">
<Value>InteractionInfo</Value>
</Value>
</Data>
<DefaultData>ResponseEmailRequestDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}

