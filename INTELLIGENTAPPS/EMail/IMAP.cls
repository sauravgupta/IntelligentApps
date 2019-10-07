Include Ensemble
Class EMail.IMAP Extends %RegisteredObject
{

Property Connected As %Boolean;

/// When receiving messages using IMAP, the directory where attached files will be stored 
Property AttachDir As %String;

/// We always store attachments as a part in the message.
/// If StoreAttachToFile=true and content-disposition MIME header of attachment part = "attachment",
/// we ALSO store to the directory specified in AttachDir
Property StoreAttachToFile As %Integer [ InitialExpression = 0 ];

/// We always store attachments as a part in the message.
/// If StoreInlineToFile=true and content-disposition MIME header of attachment part = "inline",
/// we ALSO store to the directory specified in AttachDir
Property StoreInlineToFile As %Integer [ InitialExpression = 0 ];

Property Debug As %Integer [ InitialExpression = 0 ];

/// The port of the IMAP server, the default is 143 for plain text and 993 for SSL. 
Property port As %Integer;

/// Default port is 143 for plain text and 993 for SSL.
Method portGet() As %Integer [ CodeMode = expression, Internal ]
{
$select(i%port'="":i%port,1:$select('..UseSTARTTLS&&(..SSLConfiguration'=""):993,1:143))
}

/// The read timeout in seconds to use when communicating with the IMAP server
Property timeout As %Integer [ InitialExpression = 30 ];

/// The name of the activated TLS/SSL configuration to use for pop3s requests.
Property SSLConfiguration As %String;

/// If true then the STARTTLS extension to IMAP (RFC 2595) should be used to authenticate 
/// to the IMAP server on the normal IMAP port.
/// The SSLConfiguration must be specified.
Property UseSTARTTLS As %Boolean;

/// TCP device actually used for communicating with the IMAP server.
Property dev As %String;

/// List of folders is sent back with one of two different separator characters by the IMAP server
/// gmail imap server sends back "/"
/// intersystemslabs mail server sends back "."
Parameter gmailSeparator = "/";

Parameter islSeparator = ".";

ClassMethod MailError(pErrorCode As %Integer, line As %String) As %String [ CodeMode = expression ]
{
$$$ERROR(pErrorCode,line)
}

/// <P>Open connection to IMAP server on a specific port (default value is 143).</P>
/// <ul>
/// <li>Begin TLS negotiation if necessary.</li>
/// <li>Login with a specif account.</li>
/// </ul>
Method Connect(ImapServer As %String, UserName As %String, Password As %String) As %Status
{
	Set tSC=$$$OK
	#; get server port
	Set:..port="" ..port=..portGet()
	#; Establish a connection on server
	Set tSC=..ConnectPort(ImapServer,..port) If $$$ISERR(tSC) quit ..MailError($$$GeneralError,$$$CurrentMethod_" : ConnectPort() error :"_tSC)
	#; begin TLS negotiation
	Set tSC = ..Starttls() If $$$ISERR(tSC) quit ..MailError($$$GeneralError,$$$CurrentMethod_" : Starttls() error :"_tSC)
	#; login with an account
	Set tSC=..Login(UserName,Password) If $$$ISERR(tSC) quit ..MailError($$$GeneralError,$$$CurrentMethod_" : Login() error :"_tSC)
	Quit tSC
}

/// <P>The LOGIN command identifies the client to the server and carries the plaintext password authenticating this user.</P>
Method Login(UserName As %String, Password As %String) As %Status [ Internal, Private ]
{
	If '..Connected quit ..MailError($$$NotConnectedError,$$$CurrentMethod_" : Not connected to IMAP server.")
	If $get(UserName)="" quit ..MailError($$$GeneralError,$$$CurrentMethod_" : UserName parameter to connect IMAP server is missing.")
	If $get(Password)="" quit ..MailError($$$GeneralError,$$$CurrentMethod_" : Password parameter to connect IMAP server is missing.")
 
 	Set iosave=$io
 	Set $ZTrap="LoginError"
 	Use ..dev 
 	Set timeout=..timeout
 
 	Write ". LOGIN "_UserName_" "_Password,!
  	Do
 	{
		Read line:timeout
 	}
 	While (($P(line," ",1,2)'=". OK") && ($P(line," ",1,2)'=". BAD") && ($P(line," ",1,2)'=". NO"))

 	If (($P(line," ",1,2)=". BAD") || ($P(line," ",1,2)=". NO")) use iosave quit ..MailError($$$GeneralError,$$$CurrentMethod_" : "_line)
 
 	Use iosave
 	Quit $$$OK
LoginError
 	Set $ZTrap=""
 	Set ..Connected=0
 	If ..dev'="" close ..dev
 	Set ..dev=0
 	Use iosave
 	Quit ..MailError($$$ConnectionTerminated,$$$CurrentMethod_" : Connection Terminated.")
}

/// <P>Begin TLS negotiation.</P>
Method Starttls() As %Status [ Internal, Private ]
{
	If '..Connected quit ..MailError($$$NotConnectedError,$$$CurrentMethod_" : Not connected to IMAP server.")
 
 	Set iosave=$io
 	Set $ZTrap="StarttlsError"
 	Use ..dev 
 	Set timeout=..timeout
 	Set line=""
 
 	If ..UseSTARTTLS {
 		Write ". STARTTLS",!
 		Read line:timeout
 		If $P(line," ",1,2)'=". OK" use iosave quit ..MailError($$$GeneralError,$$$CurrentMethod_" : "_line)
	
 		Use dev:(::/TLS=..SSLConfiguration)
 		Do $zu(96,18,2,"RAW")  ; always input in RAW mode - conversions to be done later.
 	}
 
 	Use iosave
 	Quit $$$OK
StarttlsError
 	Set $ZTrap=""
 	Set ..Connected=0
 	If ..dev'="" close ..dev
 	Set ..dev=0
 	Use iosave
 	Quit ..MailError($$$ConnectionTerminated,$$$CurrentMethod_" : Connection Terminated.")
}

/// <P>Open connection to IMAP server.</P>
/// <TABLE BORDER>
///     <TR>
/// 		<TD><var>ImapServer</var></TD> <TD>Address of IMAP server</TD>
/// 	</TR>
/// 	<TR>
/// 		<TD><var>ImapPort</var></TD> <TD>Port of IMAP server default value is 143</TD>
/// 	</TR>
/// </TABLE>
Method ConnectPort(ImapServer As %String, ImapPort As %Integer = 143) As %Status [ Internal, Private ]
{
	If ..Connected quit ..MailError($$$ConnectedError,$$$CurrentMethod_" : Already connected to IMAP server.")
 	If $get(ImapServer)="" quit ..MailError($$$GeneralError,$$$CurrentMethod_" : adresss of IMAP server is missing.")
 
 	If ..UseSTARTTLS,..SSLConfiguration="" quit ..MailError($$$STARTTLSConfigRequired,$$$CurrentMethod_" : STARTTLS Config Required.")
 	Set opened=0
 	Set iosave=$io
 	Set $ZTrap="ConnectPortError"

 	Set dev="|TCP|143" 
 	; IMAP port 143 for TCP and 993 for SSL
 	Set timeout=..timeout
 	If '..UseSTARTTLS,..SSLConfiguration'="" {
 		Open dev:(ImapServer:ImapPort:"CST":/TLS=..SSLConfiguration):timeout
 	} else {
 		Open dev:(ImapServer:ImapPort:"CST"):timeout
 	  }
 	  Else  quit ..MailError($$$GeneralError,$$$CurrentMethod_" : IMAP server "_ImapServer_" doesn't response with the port : "_ImapPort)
 
 	Set opened=1
 	Use dev
 	Do $zu(96,18,2,"RAW")  ; always input in RAW mode - conversions to be done later.
 	Read line:timeout
 	If $P(line," ",1,2)'="* OK" use iosave close dev quit ..MailError($$$GeneralError,$$$CurrentMethod_" : "_line)
 
 	Set ..dev=dev
 	Set ..Connected=1
 	Use iosave 
 	Quit $$$OK
ConnectPortError
 	Set $ZTrap=""
 	If opened use iosave close dev
 	Quit ..MailError($$$ConnectionFailed,$$$CurrentMethod_" : Connection Failed.")
}

/// <P>Add a flag to the mail message. 
/// Use STORE IMAP command and it returns the new flag list.</P>
/// <TABLE BORDER>
///     <TR>
/// 		<TD><var>uid</var></TD> <TD>UID number of mail message in mail box</TD>
/// 	</TR>
/// 	<TR>
/// 		<TD><var>pFlag</var></TD> <TD>Flag to add</TD>
/// 	</TR>
/// </TABLE>
Method AddFlagToMessage(uid As %Integer, pFlag As %String) As %Status [ Internal, Private ]
{
	If '..Connected quit ..MailError($$$NotConnectedError,$$$CurrentMethod_" : Not connected to IMAP server.")
 	If $get(uid)="" quit ..MailError($$$GeneralError,$$$CurrentMethod_" :  UID number is missing.")
 	If $get(pFlag)="" quit ..MailError($$$GeneralError,$$$CurrentMethod_" :  Flag to add is missing.")
 
 	Set iosave=$io
 	Set timeout=..timeout
 	Set $ZTrap="AddFlagToMessageError"
 	Use ..dev 
 
 	Write ". UID STORE "_uid_" +FLAGS ("_pFlag_")",!
 	Do
 	{
		Read line:timeout
 	}
 	While (($P(line," ",1,2)'=". OK") && ($P(line," ",1,2)'=". BAD") && ($P(line," ",1,2)'=". NO"))

 	If (($P(line," ",1,2)=". BAD") || ($P(line," ",1,2)=". NO")) quit ..MailError($$$GeneralError,$$$CurrentMethod_" : "_line)
 
 	Use iosave
 	Quit $$$OK
AddFlagToMessageError
 	Set $ZTrap=""
 	Set ..Connected=0
 	If ..dev'="" close ..dev
 	Set ..dev=0
	Use iosave
	Quit ..MailError($$$ConnectionTerminated,$$$CurrentMethod_" : Connection Terminated.")
}

/// <P>Remove all mail messages which have the \Deleted flag. Use method <METHOD>AddFlagToMessage</METHOD> to add flag \Deleted and use EXPUNGE IMAP command to suppress the mail in the mail box.</P>
Method CommitDeleteMessage(uid As %Integer) As %Status [ Internal, Private ]
{
	If '..Connected quit ..MailError($$$NotConnectedError,$$$CurrentMethod_" : Not connected to IMAP server.")
	If $get(uid)="" quit ..MailError($$$GeneralError,$$$CurrentMethod_" :  UID number is missing.")
 
 	Set tSC=$$$YES
 	For tFlag="\Seen","\Deleted"
 	{
 		Set tSC=..AddFlagToMessage(uid,tFlag) If $$$ISERR(tSC) quit 
	}
    If $$$ISERR(tSC) quit ..MailError($$$GeneralError,$$$CurrentMethod_" : Server IMAP error :"_tSC)
    
 	Set iosave=$io
 	Set timeout=..timeout
 	Set $ZTrap="CommitDeleteMessageError"
 	Use ..dev 
 
 	Write ". EXPUNGE",!
 	Do
 	{
		Read line:timeout
 	}
 	While (($P(line," ",1,2)'=". OK") && ($P(line," ",1,2)'=". BAD") && ($P(line," ",1,2)'=". NO"))

 	If (($P(line," ",1,2)=". BAD") || ($P(line," ",1,2)=". NO")) quit ..MailError($$$GeneralError,$$$CurrentMethod_" : "_line)
 
 	Use iosave
 	Quit $$$OK
CommitDeleteMessageError
 	Set $ZTrap=""
 	Set ..Connected=0
 	If ..dev'="" close ..dev
 	Set ..dev=0
 	Use iosave
 	Quit ..MailError($$$ConnectionTerminated,$$$CurrentMethod_" : Connection Terminated.")
}

/// <P>Rollback deletes using CLOSE IMAP command.</P>		
Method RollbackDeletes() As %Status [ Internal, Private ]
{
	If '..Connected quit ..MailError($$$NotConnectedError,$$$CurrentMethod_" : Not connected to IMAP server.")

 	Set iosave=$io
 	Set $ZTrap="RollbackDeletesError"
 	Set timeout=..timeout
 	Use ..dev
 	
 	Write ". CLOSE",!
 	Read line:timeout
 	If $P(line," ")'=". OK" use iosave quit ..MailError($$$GeneralError,$$$CurrentMethod_" : "_line)
 
 	Use iosave
 	Quit $$$OK
RollbackDeletesError
 	Set $ZTrap=""
 	Set ..Connected=0
 	If ..dev'="" close ..dev
 	Set ..dev=0
 	Use iosave
 	Quit ..MailError($$$ConnectionTerminated,$$$CurrentMethod_" : Connection Terminated.")
}

/// <P>Quit and commit the seesion. Use LOGOUT IMAP command.</P>
Method QuitAndCommit() As %Status [ Internal ]
{
	If '..Connected quit ..MailError($$$NotConnectedError,$$$CurrentMethod_" : Not connected to IMAP server.")

 	Set iosave=$io
 	Set $ZTrap="QuitAndCommitError"
 	Set timeout=..timeout
 	Use ..dev 
 	
 	Write ". LOGOUT",!
 	Do
 	{
		Read line:timeout
 	}
 	While (($P(line," ",1,2)'=". OK") && ($P(line," ",1,2)'=". BAD") && ($P(line," ",1,2)'=". NO"))

 	If (($P(line," ",1,2)=". BAD") || ($P(line," ",1,2)=". NO")) quit ..MailError($$$GeneralError,$$$CurrentMethod_" : "_line)
 
 	Goto QuitAndCommitExit
QuitAndCommitError
 	Set $ZTrap=""
 	Quit ..MailError($$$ConnectionTerminated,$$$CurrentMethod_" : Connection Terminated.")
QuitAndCommitExit
 	Close ..dev
 	Set ..Connected=0
 	Set ..dev=0
 	Use iosave
 	Quit $$$OK
}

/// <P>Ping the IMAP server. The NOOP command can be used as a periodic poll for new messages or
/// message status updates during a period of inactivity.  
/// The NOOP command can also be used to reset any inactivity autologout timer on the server.</P>
/// Use NOOP IMAP command.
Method Ping() As %Status [ Internal, Private ]
{
	If '..Connected quit ..MailError($$$NotConnectedError,$$$CurrentMethod_" : Not connected to IMAP server.")

 	Set iosave=$io
 	Set $ZTrap="PingError"
 	Use ..dev 
 	Set timeout=..timeout
 	Set response=""
 
 	Write ". NOOP",!
 	Read line:timeout
 	If $P(line," ",1,2)'=". OK"  use iosave close ..dev quit ..MailError($$$GeneralError,$$$CurrentMethod_" : "_line)
 
 	Use iosave
 	Quit $$$OK
PingError
 	Set $ZTrap=""
 	Set ..Connected=0
 	If ..dev'="" close ..dev
 	Set ..dev=0
 	Use iosave
 	Quit ..MailError($$$ConnectionTerminated,$$$CurrentMethod_" : Connection Terminated.")
}

/// <p>List of all namespaces for this account.</p>
Method ListNamespaces(Output response As %String) As %Status
{
	If '..Connected quit ..MailError($$$NotConnectedError,$$$CurrentMethod_" : Not connected to IMAP server.")

 	Set iosave=$io
 	Set $ZTrap="ListNamespacesError"
 	Use ..dev 
 	Set timeout=..timeout
 	Set line=""
 
 	Write ". NAMESPACE",!
 	Do
 	{
		Set response=response_line_$c(13)
		Read line:timeout
 	}
 	While (($P(line," ",1,2)'=". OK") && ($P(line," ",1,2)'=". BAD") && ($P(line," ",1,2)'=". NO"))

 	If (($P(line," ",1,2)=". BAD") || ($P(line," ",1,2)=". NO")) use iosave close ..dev quit ..MailError($$$GeneralError,$$$CurrentMethod_" : "_line)
	
 	Use iosave
 	Quit $$$OK
ListNamespacesError
 	Set $ZTrap=""
 	Set ..Connected=0
 	If ..dev'="" close ..dev
 	Set ..dev=0
 	Use iosave
 	Quit ..MailError($$$ConnectionTerminated,$$$CurrentMethod_" : Connection Terminated.")
}

/// <p>List of all mailbox names in a namespace.</p>
/// For example :<br>
///  <blockquote>
///  * LIST (\HasChildren) "/" "Association Guillaume"<br>
///  * LIST (\HasNoChildren) "/" "Association Guillaume/Maquette"<br>
///  * LIST (\HasNoChildren) "/" "Assurance"<br>
///  * LIST (\HasNoChildren) "/" "Auto entrepreneur"<br>
///  * LIST (\HasNoChildren) "/" "FranFinance"<br>
///  * LIST (\HasNoChildren) "/" "H&APQ-pitaux Lausanne"<br>
///  * LIST (\HasNoChildren) "/" "INBOX"
///  </blockquote>
Method ListFolders(ByRef ListOfMailboxes As %ArrayOfDataTypes) As %Status
{
	If '..Connected quit ..MailError($$$NotConnectedError,$$$CurrentMethod_" : Not connected to IMAP server.")
 	
 	Set iosave=$io
 	Set $ZTrap="ListFoldersError"
 	Use ..dev 
 	Set timeout=..timeout
 	Set ListOfMailboxes=##class(%ArrayOfDataTypes).%New()
    Set i=0
    
 	Write ". LIST """" *",!
 	Do
 	{
		Read line:timeout
		
		Set noselect=$p(line,"/")["\Noselect"
		Set drafts=$p(line,"/")["\Drafts"
		Set trash=$p(line,"/")["\Trash"
		Set important=$p(line,"/")["\Important"
		Set junk=$p(line,"/")["\Junk"
		Set flagged=$p(line,"/")["\Flagged"
		Set all=$p(line,"/")["\All"
		Set archived=$p(line,"/")["\Archive"
		Set junkisl=$p(line," ",6)["INBOX.Junk"
		Set sentisl=$p(line," ",7)["INBOX.Sent"
		
		If (($P(line," ",1,2)="* LIST")&&('noselect)&&('drafts)&&('trash)&&('important)&&('junk)&&('flagged)&&('all)&&('archived)&&('junkisl)&&('sentisl)) {
			//Set response = $P(line,"/",2,*)
			//specify IMAP server specific separator character
			//and try both.
			Set response = $P(line,..#gmailSeparator,2,*)
			if response = "" {
				//didn't work with the gmail separator character "/"
				//Try intersystemslabs mail server separator character "."
				Set response = $P(line,..#islSeparator,2,*)
			}
			Set response = $zstrip($zstrip($E(response,3,*),"<>","W"),"<>","""")
			Do ListOfMailboxes.SetAt(response,$I(i))
		}
 	}
 	While (($P(line," ",1,2)'=". OK") && ($P(line," ",1,2)'=". BAD") && ($P(line," ",1,2)'=". NO"))

 	If (($P(line," ",1,2)=". BAD") || ($P(line," ",1,2)=". NO")) use iosave close ..dev quit ..MailError($$$GeneralError,$$$CurrentMethod_" : "_line)

 	Use iosave
 	Quit $$$OK
ListFoldersError
 	Set $ZTrap=""
 	Set ..Connected=0
 	If ..dev'="" close ..dev
 	Set ..dev=0
 	Use iosave
 	Quit ..MailError($$$ConnectionTerminated,$$$CurrentMethod_" : Connection Terminated.")
}

/// <P>Select mailbox by folder.
/// With Gmail server RECENT flags are not supported.</P>
/// An example of STATUS query with folder="INBOX" :
///  <blockquote>
///  * STATUS "INBOX" (MESSAGES 28 RECENT 0 UIDNEXT 5397 UNSEEN 1)<br>
///  . OK Success
///  </blockquote>
Method StatusFolder(pFolder As %String, ByRef SelectingFolder As %ArrayOfDataTypes, Output r As %String) As %Status [ Private ]
{
	If '..Connected quit ..MailError($$$NotConnectedError,$$$CurrentMethod_" : Not connected to IMAP server.")
 
 	Set iosave=$io
 	Set $ZTrap="SelectFolderError"
 	Use ..dev 
 	Set timeout=..timeout
 	Set SelectingFolder=##class(%ArrayOfDataTypes).%New()
 	Set StatusMailbox=##class(%ArrayOfDataTypes).%New()
 	Set line=""
 
 	Write ". STATUS """_pFolder_""" (UIDNEXT MESSAGES RECENT UNSEEN)",!
 	Do
 	{
		Read line:timeout
		If $P(line," ",1,2)="* STATUS" {
			Set line=$zstrip(line,"*","()")
			Do StatusMailbox.SetAt($P(line," ",5),$P(line," ",4)) ; total number of mails in the folder 
			Do StatusMailbox.SetAt($P(line," ",7),$P(line," ",6)) ; total number of recent mails in the folder
			Do StatusMailbox.SetAt($P(line," ",9),$P(line," ",8)) ; next uid
			Do StatusMailbox.SetAt($P(line," ",11),$P(line," ",10)) ; total number of unseen mails in the folder
		}
 	}
 	While (($P(line," ",1,2)'=". OK") && ($P(line," ",1,2)'=". BAD") && ($P(line," ",1,2)'=". NO"))

 	If (($P(line," ",1,2)=". BAD") || ($P(line," ",1,2)=". NO")) use iosave close ..dev quit ..MailError($$$GeneralError,$$$CurrentMethod_" : "_line)
 
 	Do SelectingFolder.SetAt(StatusMailbox,pFolder)
 
 	Use iosave
 	Quit $$$OK
SelectFolderError
 	Set $ZTrap=""
 	Set ..Connected=0
 	If ..dev'="" close ..dev
 	Set ..dev=0
 	Use iosave
 	Quit ..MailError($$$ConnectionTerminated,$$$CurrentMethod_" : Connection Terminated.")
}

/// <p>The SELECT command selects a mailbox so that messages in the mailbox can be accessed.</p>
/// <var>pFolder</var> mailbox name
Method SelectFolder(pFolder As %String) As %Status [ Internal, Private ]
{
	If '..Connected quit ..MailError($$$NotConnectedError,$$$CurrentMethod_" : Not connected to IMAP server.")
	If $get(pFolder)="" quit ..MailError($$$GeneralError,$$$CurrentMethod_" :  Mailbox Naming is missing.")
	
	Set iosave=$io
	Set $ZTrap="SelectFolderError"
	Use ..dev 
	Set timeout=..timeout
	
	Write ". SELECT """_pFolder_"""",!
	Do
	{
		Read line:timeout
	}
	While (($P(line," ",1,2)'=". OK") && ($P(line," ",1,2)'=". BAD") && ($P(line," ",1,2)'=". NO"))
	
	If (($P(line," ",1,2)=". BAD") || ($P(line," ",1,2)=". NO")) use iosave quit ..MailError($$$GeneralError,$$$CurrentMethod_" : "_line) 
	
	Use iosave
	Quit $$$OK
SelectFolderError
	Set $ZTrap=""
	Set ..Connected=0
	If ..dev'="" close ..dev
	Set ..dev=0
	Use iosave
	Quit ..MailError($$$ConnectionTerminated,$$$CurrentMethod_" : Connection Terminated")
}

/// <P>This method searches the mailbox for messages that match the given searching criteria.</P>
/// The untagged SEARCH response from the server contains a listing of UID message sequence numbers corresponding to
/// those messages that match the searching criteria. 
/// <TABLE BORDER>
///     <TR>
/// 		<TD><var>SearchingCriteria</var></TD> <TD>Searching criteria</TD>
/// 	</TR>
/// 	<TR>
/// 		<TD><var>ListOfUIDs</var></TD> <TD>List of message UID numbers</TD>
/// 	</TR>
/// </TABLE>
Method GetMessagesUID(SearchingCriteria As %String, Output ListOfUIDs As %Library.List) As %Status [ Private ]
{
	If '..Connected quit ..MailError($$$NotConnectedError,$$$CurrentMethod_" : Not connected to IMAP server.")
	If SearchingCriteria="" quit ..MailError($$$GeneralError,$$$CurrentMethod_" :  Searching criteria is not defined.")
	
 	Set iosave=$io
 	Set $ZTrap="GetMessagesUIDError"
 	Use ..dev 
 	Set timeout=..timeout
 
 	Write ". UID SEARCH "_SearchingCriteria,!
 	Do
 	{
		Read line:timeout
		If ($P(line," ",1,2)="* SEARCH") s ListOfUIDs=$LISTFROMSTRING($p(line," ",3,*)," ")
 	}
 	While (($P(line," ",1,2)'=". OK") && ($P(line," ",1,2)'=". BAD") && ($P(line," ",1,2)'=". NO"))

 	If (($P(line," ",1,2)=". BAD") || ($P(line," ",1,2)=". NO")) use iosave quit ..MailError($$$GeneralError,$$$CurrentMethod_" :"_line)
 
 	Use iosave
 	Quit $$$OK
GetMessagesUIDError
 	Set $ZTrap=""
 	Set ..Connected=0
 	If ..dev'="" close ..dev
 	Set ..dev=0
 	Use iosave
 	Quit ..MailError($$$ConnectionTerminated,$$$CurrentMethod_" : Connection Terminated")
}

/// <P>Size of each messages</P>
/// <TABLE BORDER>
///     <TR>
/// 		<TD><var>ListOfUIDs</var></TD> <TD>List of messages by UID</TD>
/// 	</TR>
/// 	<TR>
/// 		<TD><var>UIDArray</var></TD> <TD>Array of UID sequence message number and size number</TD>
/// 	</TR>
/// </TABLE>
Method SizeMessages(pFolder As %String, ListOfUIDs As %Library.List, UIDArray As %ArrayOfDataTypes) As %Status [ Internal, Private ]
{
	If '..Connected quit ..MailError($$$NotConnectedError,$$$CurrentMethod_" : Not connected to IMAP server.")
	If $get(ListOfUIDs)="" quit ..MailError($$$GeneralError,$$$CurrentMethod_" :  UID list is missing.")
	
 	Set iosave=$io
 	Set $ZTrap="SizeMessagesError"
 	Use ..dev 
 	Set timeout=..timeout
 	
 	Set NumberOfBytes=0
 	For variable = 1:1:$ll(ListOfUIDs)
 	{
		Set uid=$LIST(ListOfUIDs,variable)
		
		Set InfosArray=##class(%ArrayOfDataTypes).%New()
 	 	Do InfosArray.SetAt(0,"size")
	 	Do InfosArray.SetAt(pFolder,"folder")
		
 		Write ". UID FETCH "_uid_" RFC822.SIZE",!
 		Do
 		{
 			Read line:timeout
 			
 			If ($P(line," ",1)="*") {
	 			Set UIDSize=$zstrip($p(line," ",7),">",")") ; size
 	 			Do InfosArray.SetAt(UIDSize,"size")
	 			Do InfosArray.SetAt(pFolder,"folder")
	 		} 
	 		Do UIDArray.SetAt(InfosArray,uid) ; UID
	 		
 		}
 		While (($P(line," ",1,2)'=". OK") && ($P(line," ",1,2)'=". BAD") && ($P(line," ",1,2)'=". NO"))

 		If (($P(line," ",1,2)=". BAD") || ($P(line," ",1,2)=". NO")) use iosave quit 
 	}
 
 	Use iosave
 	Quit $$$OK
SizeMessagesError
 	Set $ZTrap=""
 	Set ..Connected=0
 	If ..dev'="" close ..dev
 	Set ..dev=0
 	Use iosave
 	Quit ..MailError($$$ConnectionTerminated,$$$CurrentMethod_" : Connection Terminated")
}

/// <P>[RFC-2822] message of a particular body section.<P>
/// <TABLE BORDER>
///     <TR>
/// 		<TD><var>pFolder</var></TD> <TD>Mail box name</TD>
/// 	</TR>
/// 	<TR>
/// 		<TD><var>uid</var></TD> <TD>UID of mail message</TD>
/// 	</TR>
///     <TR>
/// 		<TD><var>partIdx</var></TD> <TD>Section specification</TD>
/// 	</TR>
///     <TR>
/// 		<TD><var>tencoding</var></TD> <TD>Content Transfer Encoding of the body part</TD>
/// 	</TR>
///     <TR>
/// 		<TD><var>stream</var></TD> <TD>Body section retuned into a stream</TD>
/// 	</TR>
/// </TABLE>
Method FetchBody(pFolder As %String, uid As %Integer, partIdx As %String, tencoding As %String, stream As %Stream.Object) As %Status [ Internal, Private ]
{
	If $get(pFolder)="" quit ..MailError($$$GeneralError,$$$CurrentMethod_" :  Mailbox Naming is missing.")
	Set tSC=..SelectFolder(pFolder) If $$$ISERR(tSC) quit ..MailError($$$GeneralError,$$$CurrentMethod_" : SelectFolder() error :"_tSC)
 
 	If '..Connected quit ..MailError($$$NotConnectedError,$$$CurrentMethod_" : Not connected to IMAP server.")
 
 	Set iosave=$io
 	Set $ZTrap="FetchBodyError"
 	Use ..dev 
 	Set timeout=..timeout
 	Set:partIdx="" partIdx="TEXT"
 	
 	Set pFlag=$ZQASCII("COHIBA13")
 	Set pFlagOK=pFlag_" OK"
 	
 	Write pFlag_" UID FETCH "_uid_" BODY["_partIdx_"]",!
 	Read line:timeout
 	If (($P(line," ",1,2)=(pFlag_" BAD")) || ($P(line," ",1,2)=(pFlag_" NO"))) use iosave quit ..MailError($$$GeneralError,$$$CurrentMethod_" : "_line)
 	Set crlf=1
 	Set prevcrlf=0
 	Set streamtemp=##class(%FileCharacterStream).%New()
 	Do
 	{
	 	Read line:timeout
	 	
	 	If ($P(line," ",1,2)'=pFlagOK){
	 	
	 		Set crlf=($extract(line,*-1,*)=$c(13,10))
	 		If tencoding="base64" {
		 		Set line=$zstrip(line,">",")")
				Set line=##class(%Net.MIMEReader).DecodeBase64(line)
				Do stream.Write(line)
			} Else{ 
				If tencoding="quoted-printable" {
					Set line=$zstrip(line,">","=")
					Set line=##class(%Net.MIMEReader).DecodeQP(line)
				    Set line=$tr(line,$c(9)," ")
					If crlf Set line=$extract(line,1,*-2)
					If prevcrlf Set line=$c(13,10)_line
					Set prevcrlf=crlf
					Do streamtemp.WriteLine(line) ; html message
				} Else {
					Set line=$tr(line,$c(9)," ")
					If crlf Set line=$extract(line,1,*-2)
					If prevcrlf Set line=$c(13,10)_line
					Set prevcrlf=crlf
					Do streamtemp.WriteLine(line) ; text message with a line terminator
				}
			} 
 		
	 	}
 	
 	} While ($P(line," ",1,2)'=pFlagOK)
 	
 	#; delete the last character ")" of the stream which is not a character of the mail message.
 	#; it's the end of the response of IMAP FETCH command. 
 	If tencoding'="base64" {
	 	
	 		While 'streamtemp.AtEnd {
				Set ligne=streamtemp.ReadLine()
				If (ligne'=")")||('streamtemp.AtEnd=1) {do stream.WriteLine(ligne)}
			
	 	
	 	}
 	}
 	
 	Use iosave
 	Quit tSC
FetchBodyError
 	Set $ZTrap=""
 	Set ..Connected=0
 	If ..dev'="" close ..dev
 	Set ..dev=0
 	Use iosave
 	Quit ..MailError($$$ConnectionTerminated,$$$CurrentMethod_" : Connection Terminated")
}

/// <P>Get MESSAGE-ID value into [RFC-2822] header of the message.</P>
/// <TABLE BORDER>
///     <TR>
/// 		<TD><var>pFolder</var></TD> <TD>Mail box name</TD>
/// 	</TR>
/// 	<TR>
/// 		<TD><var>uid</var></TD> <TD>UID of mail message</TD>
/// 	</TR>
///     <TR>
/// 		<TD><var>messageId</var></TD> <TD>Message-ID</TD>
/// 	</TR>
/// </TABLE>
Method GetMessageId(pFolder As %String, uid As %Integer, ByRef messageId As %String) As %Status [ Internal ]
{
	If $get(pFolder)="" quit ..MailError($$$GeneralError,$$$CurrentMethod_" :  Mailbox Naming is missing.")
	Set tSC=..SelectFolder(pFolder) If $$$ISERR(tSC) quit ..MailError($$$GeneralError,$$$CurrentMethod_" : SelectFolder() error :"_tSC)
  
 	If '..Connected quit ..MailError($$$NotConnectedError,$$$CurrentMethod_" : Not connected to IMAP server.")
  	If $get(uid)="" quit ..MailError($$$GeneralError,$$$CurrentMethod_" :  Uid parameter of the mail is missing.")
 	
 	Set messageId=""
 	Set iosave=$io
 	Set $ZTrap="GetMessageIdError"
 	Use ..dev 
 	Set timeout=..timeout
 
 	Write ". UID FETCH "_uid_" BODY.PEEK[HEADER.FIELDS (MESSAGE-ID)]",!
 	Do
 	{
 		Read line:timeout
 		If $zconvert($P(line,":",1),"L")="message-id" set messageId=$P(line,":",2)
 	}
 	While (($P(line," ",1,2)'=". OK") && ($P(line," ",1,2)'=". BAD") && ($P(line," ",1,2)'=". NO"))

 	if ($P(line," ",1,2)=". BAD") use iosave quit ..MailError($$$GeneralError,$$$CurrentMethod_" : "_line)
 
 
 	Use iosave
 	Quit $$$OK
GetMessageIdError
 	Set $ZTrap=""
 	Set ..Connected=0
 	If ..dev'="" close ..dev
 	Set ..dev=0
 	Use iosave
 	Quit ..MailError($$$ConnectionTerminated,$$$CurrentMethod_" : Connection Terminated")
}

/// <P>A [MIME-IMB] body part, or a [MIME-IMB] header.</P>
/// <TABLE BORDER>
///     <TR>
/// 		<TD><var>pFolder</var></TD> <TD>Mail box name</TD>
/// 	</TR>
/// 	<TR>
/// 		<TD><var>uid</var></TD> <TD>UID of mail message</TD>
/// 	</TR>
///     <TR>
/// 		<TD><var>partIdx</var></TD> <TD>Section specification</TD>
/// 	</TR>
///     <TR>
/// 		<TD><var>MsgHeadersArray</var></TD> <TD>Array of [MIME-IMB] body part, or a [MIME-IMB] header</TD>
/// 	</TR>
/// </TABLE>		
Method FetchHeadersPart(pFolder As %String, uid As %Integer, partIdx As %String, ByRef MsgHeadersArray As %ArrayOfDataTypes) As %Status
{
	If '..Connected quit ..MailError($$$NotConnectedError,$$$CurrentMethod_" : Not connected to IMAP server.")
 	If $get(uid)="" quit ..MailError($$$GeneralError,$$$CurrentMethod_" :  Uid parameter of the mail is missing.")
 	set tSC=$$$YES
 	If $get(pFolder)="" quit ..MailError($$$GeneralError,$$$CurrentMethod_" :  Mailbox Naming is missing.")
	Set tSC=..SelectFolder(pFolder) If $$$ISERR(tSC) quit ..MailError($$$GeneralError,$$$CurrentMethod_" : SelectFolder() error :"_tSC)
   
 	Set iosave=$io
 	Set $ZTrap="FetchHeadersPartError"
 	Set timeout=..timeout
 	Use ..dev
 
 	Write ". UID FETCH "_uid_" BODY["_partIdx_"]",!
 	Read line:timeout
 	If (($P(line," ",1,2)=". BAD") || ($P(line," ",1,2)=". NO")) use iosave quit ..MailError($$$GeneralError,$$$CurrentMethod_" : "_line)
 	
 	Set tSC=..GetHeadersArray(.MsgHeadersArray)
 	
 	Use iosave
 	Quit tSC
FetchHeadersPartError
 	Set $ZTrap=""
 	Set ..Connected=0
 	If ..dev'="" close ..dev
 	Set ..dev=0
 	use iosave
 	Quit ..MailError($$$ConnectionTerminated,$$$CurrentMethod_" : Connection Terminated")
}

/// Assumes current device is TCP socket to IMAP server.
Method GetHeadersArray(ByRef MsgHeadersArray As %ArrayOfDataTypes) As %Status [ Internal ]
{
	#; In RFC822 (non-MIME) and in MIME the message text is separated from
 	#; the headers by a blank line
 	Set MsgHeadersArray=##class(%ArrayOfDataTypes).%New()
 	Set timeout=..timeout
 	Set headerNum=0
 	Do {
	 	Read line:timeout
	 	If ((line'="") && ($zconvert($p(line," ",1,2),"L")'=". ok")&& (line'=")")) {
		
		 	If ..BeginsWithSpace(line)&&(headerNum>0) {
			 	Set strippedLine=$zstrip(line,"<W") 
			 	Set sep=" "
			 	Set word=$piece($tr(strippedLine,$c(9)," ")," ",1)
			 	If ($length(word,"?=")>1) && ($extract($piece(word,"?",5))="=") set sep=""
			 	Set headerLines(headerNum)=headerLines(headerNum)_sep_strippedLine
		 	} else {
			 	Set headerNum=headerNum+1
			 	Set headerLines(headerNum)=line
		 	}
	 	}
	 
 	} While ($P(line," ",1,2)'=". OK")
 
 	Set done=0
 
 	#; set headers we have gathered at beginning
 	Set $ZTrap="FetchMessageHeadersUnexpected"
 	Set headerIndex=$o(headerLines(""))
 	While headerIndex'="" {
	 	Set headerLine=headerLines(headerIndex)
	 	If (headerLine'="") {
		 	Set hdr=$zconvert($piece(headerLine,":",1),"L")
		 	Set line=##class(%Net.MIMEReader).DecodeHeader($zstrip($extract(headerLine,$length(hdr)+2,$length(headerLine)),"<W"))
		 	If MsgHeadersArray.GetAt(hdr)="" {
			 	Do MsgHeadersArray.SetAt(line,hdr)
		 	} else {	
			 	Do MsgHeadersArray.SetAt(MsgHeadersArray.GetAt(hdr)_$C(13,10)_line,hdr)
		 	}
	 	}
	 	Set headerIndex=$o(headerLines(headerIndex))
 	}
 	Quit $$$OK
FetchMessageHeadersUnexpected
 	Set $ZTrap=""
	Quit ..MailError($$$GeneralError,$$$CurrentMethod_" : unexpected error; "_$ze)
}

Method SetDestList(destlist As %ListOfDataTypes, dests As %String) As %Status [ Internal, Private ]
{
	Set count=$length(dests,",")
 	For i=1:1:count {
		Set address=$zstrip($piece(dests,",",i),"<>W")
		If address'="" do destlist.Insert(address)
 	}
 	Quit 1
}

ClassMethod BeginsWithSpace(x As %String) As %Integer [ Internal, Private ]
{
 	Quit ($extract(x,1)=" ")!($extract(x,1)=$char(9))
}

}

