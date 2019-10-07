/// Reference : RFC 2060, RFC 3501  - Internet Message Access Protocol - Version 4rev1
Class EMail.FetchImapProtocol Extends EMail.IMAP
{

/// <P>Reads the mail messages and attachements.</P>
Method FetchMail(pFolder As %String, uid As %Integer, MessageSize As %Integer, ByRef MailMsgout As %Net.MailMessage, Delete As %Boolean = 0) As %Status
{
	If '..Connected quit ..MailError($$$NotConnectedError,$$$CurrentMethod_" : Not connected to IMAP server.")
	If $get(uid)="" quit ..MailError($$$GeneralError,$$$CurrentMethod_" :  Uid parameter of the mail is missing.")
 
 	Set $ZTrap="FetchMailError"
 	Set tSC=$$$YES
 
 	Set tSC=..SelectFolder(pFolder) If $$$ISERR(tSC) quit ..MailError($$$GeneralError,$$$CurrentMethod_" : SelectFolder() error :"_tSC)
 
 	Set tSC=..GetMailMessage(pFolder,uid,.MailMsgout)
 	If '$ISOBJECT(MailMsgout) quit ..MailError($$$GeneralError,$$$CurrentMethod_" : Server IMAP error : Fail to generate mail message.")

 	Set MailMsgout.MessageSize=MessageSize
 	
 	#; Delete current message from Server
 	If Delete quit ..CommitDeleteMessage(uid)
 
 	Quit tSC
FetchMailError
 	Set $ZTrap=""
 	Quit ..MailError($$$GeneralError,$$$CurrentMethod_" : Server IMAP error : Unexpected Error "_$ze)
}

/// <P> Convert a part that represents an email message to %Net.MailMessage object.</P>
Method GetMailMessage(pFolder As %String, uid As %String, Output mailmsg As %Net.MailMessage) As %Status [ Internal, Private, ProcedureBlock = 1 ]
{
	Set sc=$$$OK
 	Set mailmsg=##class(%Net.MailMessage).%New()

 	Set $ZTrap="GetMailUnexpectedError"

 	#; walk glv global and build all message parts
 	Set part="HEADER" ; first fetch top headers of the mail
 	Set mailmsg.PartIndex=""
 	Do ..WalkParts(pFolder,uid,part,.pp,mailmsg)
 
GetMailExit
 	Set msgheaders=mailmsg.Headers
 	Do ..SetDestList(mailmsg.To,msgheaders.GetAt("to"))
 	Do ..SetDestList(mailmsg.Cc,msgheaders.GetAt("cc"))
 	Do ..SetDestList(mailmsg.Bcc,msgheaders.GetAt("bcc"))
 	Set mailmsg.From=msgheaders.GetAt("from")
 	Set mailmsg.Date=msgheaders.GetAt("date")
 	Set mailmsg.Subject=msgheaders.GetAt("subject")
 	Set mailmsg.Sender=msgheaders.GetAt("sender")
 	Set mailmsg.ReplyTo=msgheaders.GetAt("reply-to")
 
 	Quit sc

GetMailUnexpectedError
 	Set $ZTrap=""
 	Set sc=$$$ERROR($$$GeneralError,"Server IMAP error : Unexpected Error "_$ze)
 	Goto GetMailExit
}

Method WalkParts(pFolder As %String, uid As %String, part As %String, Output pp As %Boolean, msgpart As %Net.MailMessagePart) [ Internal, Private ]
{
 ;     [HEADER] a [MIME-IMB] header
 ;        [1.MIME]
 ;        [2.MIME] multipart 
 ;                          [2.1.MIME] mulitpart
 ;                                              [2.1.1.MIME] a [MIME-IMB] body part
 ;                                              [2.1.2.MIME]
 ;                          [2.2.MIME]
 ;        [3.MIME] 
 ; 
 set tSC=$$$YES
 ; Headers of a part
 set:part'="HEADER" part=part_".MIME"
 set pp=1
 set tSC=..FetchHeadersPart(pFolder,uid,part,.msgArray) ; fetch a [MIME-IMB] header or a [MIME-IMB] body part
 If $$$ISERR(tSC) {
 	If (($P(tSC,":",2)[". NO")=1) { s pp=0 } ; no part
 	Else {quit ..MailError($$$GeneralError,$$$CurrentMethod_" : Fail to generate array headers.")}
 }
 
 set msgpart.Headers=msgArray
 set type=msgpart.Headers.GetAt("content-type")

 //==================================================================//
 //it appears that the intersystemslab mail server will keep replying 
 //	//with the next mime part even after the full message has been
 //retrieved, albeit with a trailing "{0}". So we report a error and return
 if type = "" {
 	//nothing came back in the last fetch, so this is bogus, let's return
 	set tSC = "ran out of mime parts and hence returning to FetchMail"
 	set pp = 0
 	quit
 }
 //===================================================================//
 
 if pp '= 0 { ; a part exists 
 	If $piece($piece(type,";"),"/")="multipart" {  ;' this is a multipart message
		set msgpart.IsMultiPart=1
		if $piece(type,";")="multipart/alternative" set msgpart.IsAlternative=1
		set msgpart.MultiPartType = $piece($piece(type,";"),"/",2)
		set i=1
		For {
			set m=##class(%Net.MailMessagePart).%New()
			set p = msgpart.PartIndex _ $SELECT(msgpart.PartIndex="":"",1:".") _i ; hierarchy part of the message for example : 2.1.2
			set m.PartIndex=p
			do msgpart.Parts.SetAt(m,i)
			do ..WalkParts(pFolder,uid,p,.pp,m) ; next part : call WalkParts() method (recursive algorithm) 
			if pp=0 { set pp=1 do msgpart.Parts.RemoveAt(i) quit } ; if no subpart exists then go back to parent call
			set i=i+1
		}
 	} 
 	Else { ; this is not multipart
 		; find out if binary or non-binary and write to appropriate stream
 		set msgpart.ContentTransferEncoding=msgpart.Headers.GetAt("content-transfer-encoding")
 		if (type="") && (msgpart.ContentTransferEncoding="") set msgpart.ContentTransferEncoding="7bit"
 		set msgpart.ContentType=$zstrip($piece(type,";"),"<>W")
		set charset=""
		if (type'="") && $case($piece(type,"/",1),"text":0,"message":0,:1) {
			set stream=msgpart.BinaryData
			set msgpart.IsBinary=1
			;set tClassType="%FileBinaryStream"
		} else {
			set msgpart.IsBinary=0
			set msgpart.IsHTML=($piece(type,";",1)="text/html")
			set charset=$zcvt($piece($piece(type,";",2),"=",2),"L")
			; always write file as RAW to copy message from IMAP# server
			set stream=msgpart.TextData
			set stream.TranslateTable="RAW"
			;set tClassType="%FileCharacterStream"
		}
		
		; For attachment (inline or not) 
		set bAttach=0
		set contentDisposition=$zcvt($piece(msgpart.Headers.GetAt("content-disposition"),";",1),"L")
 		if $case(contentDisposition,"attachment":1,"inline":1,:0) {
	 		set:contentDisposition="inline" msgpart.InlineAttachment=1
	 		set filename=$zstrip($zcvt($piece($piece(msgpart.Headers.GetAt("content-disposition"),";",2),"=",2),"L"),"<>","""")
	 		set:filename="" filename=$zstrip($zcvt($piece($piece(type,";",2),"=",2),"L"),"<>","""")
	 		if (..StoreAttachToFile && (contentDisposition="attachment")) ||
		   (..StoreInlineToFile && (contentDisposition="inline")) {
			   set dir=##class(%File).NormalizeDirectory(..AttachDir)
			   set msgpart.Dir=dir
			   if filename="" {
					#; create a reasonable short filename based on current time
					do {
						set t=$ztimestamp
						set t=(((t-58211)*86400)+$p(t,",",2))*100000000\1+$R(100000)
						set filename="" for  set filename=filename_$c((t#32)+65),t=t\32 quit:'t
						set filename=$reverse($tr(filename,$c(91,92,93,94,95,96),"234689"))
						set filename="ATT"_filename_".dat"
					} while ##class(%File).Exists(dir_filename)
			  }
			  set path=dir_filename
			  do ##class(%File).Delete(path)
			  do stream.LinkToFile(path)
			  set bAttach=1
		   }
		   set msgpart.FileName=filename
 		}
 		; this method returns [RFC-2822] message body into stream  
 		s tSC=..FetchBody(pFolder,uid,msgpart.PartIndex,msgpart.ContentTransferEncoding,stream)
 		
		if ..StoreAttachToFile && bAttach {
			do stream.SaveStream()
		} 
 		#; Don't set Charset until last to avoid character conversions.
 		if charset'="" set msgpart.Charset=charset
 	}
 }
	
 quit tSC
}

/// <P>Get list of messages and their number of bytes which satisfy the search conditions in the mail box account.</P>
/// <TABLE BORDER>
///     <TR>
/// 		<TD><var>pSeachAllMailboxes</var></TD> <TD>If 1: search into all mail boxes for an account</TD>
/// 	</TR>
/// 	<TR>
/// 		<TD><var>pFolder</var></TD> <TD>A specific mailbox name if <var>pSeachAllMailboxes</var>=0</TD>
/// 	</TR>
/// 	<TR>
/// 		<TD><var>pSearchCriteria</var></TD> <TD>Searching criteria</TD>
/// 	</TR>
/// 	<TR>
/// 		<TD><var>WithCriteriaUIDArray</var></TD> <TD>Array of UID sequence message number with its size number and the folder name</TD>
/// 	</TR>
/// </TABLE>
Method FetchUIDMailBoxes(pSeachAllMailboxes As %Boolean, pFolder As %String, pSearchCriteria As %String, ByRef WithCriteriaUIDArray As %ArrayOfDataTypes) As %Status
{
	If '..Connected quit ..MailError($$$NotConnectedError,$$$CurrentMethod_" : Not connected to IMAP server.")
	If $get(pSeachAllMailboxes)="" quit ..MailError($$$GeneralError,$$$CurrentMethod_" :  pSeachAllMailboxes parameter is missing.")
 
	Set tSC=$$$OK
	Set $ZTrap="FetchUIDMailBoxesError"
    
    #; If pSeachAllMailboxes=1 then get all folders
    If pSeachAllMailboxes {
    	Set tSC=..ListFolders(.ListOfMailboxes) If $$$ISERR(tSC) quit ..MailError($$$GeneralError,$$$CurrentMethod_" : ListFolders() error :"_tSC)
    }
    Else {
	    Set ListOfMailboxes=##class(%ArrayOfDataTypes).%New()
	    Do ListOfMailboxes.SetAt(pFolder,1)
    }
    Set index=""
    Set WithCriteriaUIDArray=##class(%ArrayOfDataTypes).%New()
    For {
	    Set index = ListOfMailboxes.Next(index)  Quit:""=index
 		Set tOneFolder=ListOfMailboxes.GetAt(index)
 		
 		#; Select the folder in which you want to report
 		Set tSC=..SelectFolder(tOneFolder) If $$$ISERR(tSC) quit
 	    kill ListWithCriteriaOfUIDs
 		Set pSearchCriteria=$SELECT(pSearchCriteria="":"ALL",1:"ALL "_pSearchCriteria)
 		Set tSC=..GetMessagesUID(pSearchCriteria,.ListWithCriteriaOfUIDs) ; List of UID's messages found 
 		If $$$ISERR(tSC) quit
 		If $get(ListWithCriteriaOfUIDs)="" continue
 		Set tSC=..SizeMessages(tOneFolder,ListWithCriteriaOfUIDs,WithCriteriaUIDArray) ; Aray of these messages with their size
 		If $$$ISERR(tSC) quit
 		 
    }
 	Quit tSC
 	
FetchUIDMailBoxesError
 	Set $ZTrap=""
 	Set sc=$$$ERROR($$$GeneralError,"Server IMAP error : Unexpected Error "_$ze)
 	Quit sc
}

}

