
##############################################
# $Id: 98_dummy.pm 11442 2016-05-15 12:43:12Z rudolfkoenig $
package main;

use strict;
use warnings;
use SetExtensions;

my %sets = (
  "inform"  => undef,
  "quiet"   => undef,
  "message" => "textField",
);

my %sets_exclude = (
  "inform"  => undef,
  "quiet"   => undef,
);

my %gets = (
  "LastMsg"     => "textField",
  "LastMsgSend" => "textField",
);

sub
TelegramKontakt_Initialize($)
{
  my ($hash) = @_;

  $hash->{SetFn}     = "TelegramKontakt_Set";
  $hash->{GetFn}     = "TelegramKontakt_Get";
  $hash->{DefFn}     = "TelegramKontakt_Define";
  $hash->{AttrList}  = "TelegramId TelegramBot " .
                       $readingFnAttributes;
}

###################################
sub
TelegramKontakt_Set($@)
{
  my ( $hash, $name, @a ) = @_;
 
  return "no set value specified" if(int(@a) < 1);
  Log3 $name, 4, "TelegramKontakt_Set $name: called ";

  ### Check Args
  my $numberOfArgs  = int(@a);
  return "TelegramKontakt_Set: No cmd specified for set" if ( $numberOfArgs < 1 );

  my $cmd = shift @a;
  $numberOfArgs--;

  Log3 $name, 4, "TelegramKontakt_Set $name: Processing TelegramBot_Set( $cmd )";

  if (!exists($sets{$cmd}))  {
    my @cList;
    foreach my $k (keys %sets) {
      if(!exists($sets_exclude{$k}))
      {
        my $opts = undef;
        $opts = $sets{$k};
        if (defined($opts)) 
        {
          push(@cList,$k . ':' . $opts);
        } else {
          push (@cList,$k);
        } 
      }
    } # end foreach

    return "TelegramKontakt_Set: Unknown argument $cmd, choose one of " . join(" ", @cList);
  } # error unknown cmd handling

  if(($cmd eq 'inform') || ($cmd eq 'quiet'))
  {
    readingsSingleUpdate($hash,"state",$cmd,1);
  }
  elsif($cmd eq 'message')
  {
    return "TelegramKontakt_Set: No message to send" if ( $numberOfArgs < 1 );
    
    my $msg = join(" ", @a);
    readingsBeginUpdate($hash);
    readingsBulkUpdate($hash,'LastMsg',$msg);
    
    if($hash->{STATE} eq 'quiet')
    {
      readingsEndUpdate($hash,1);
      Log3 $name, 4, "TelegramKontakt_Set $name: STATE is quiet; No message sent";
      return undef;
    }
    
    readingsBulkUpdate($hash,'LastMsgSend',$msg);
    readingsEndUpdate($hash,1);
    
    my $TelegramId;
    $TelegramId = AttrVal($name,'TelegramId',undef);
    
    return "TelegramKontakt_Set: Command $cmd, requires TelegramId being set" if ( ! defined($TelegramId) );
    
    my $Bot;
    $Bot = AttrVal($name,'TelegramBot',undef);
    
    return "TelegramKontakt_Set: Command $cmd, requires TelegramBot being set" if ( ! defined($Bot) );
    
    my $m = 'TelegramBot';
    my @DefTelegramBot = devspec2array("TYPE=TelegramBot");
    Log3 $name, 4, "TelegramKontakt_Set $name: modules TelegramBot found: ". join(" ", @DefTelegramBot);
    my $BotDef;
    
    foreach my $Def (@DefTelegramBot)
    {
      if($Def eq $Bot)
      {
        $BotDef = $Def;
        last;
      }
    }
    
    if (!defined($BotDef))
    {
      return "TelegramKontakt_Set: Command $cmd, TelegramBot $Bot not defined"
    }
    
    Log3 $name, 4, "TelegramKontakt_Set $name: TelegramBot $Bot found.";
    Log3 $name, 4, "TelegramKontakt_Set $name: Sending Msg $msg";
    
    CommandSet( undef, $Bot." message \@".$TelegramId." ".$msg);    
  }
  
  return undef;
}

sub
TelegramKontakt_Define($$)
{
  my ($hash, $def) = @_;
  my @a = split("[ \t][ \t]*", $def);

  return "Wrong syntax: use define <name> TelegramKontakt" if(int(@a) != 2);
  
  $hash->{STATE} = "quiet";
  return undef;
}

sub TelegramKontakt_Get($@) {
	my ($hash, @param) = @_;
	
	return '"TelegramKontakt_Set: needs at least one argument' if (int(@param) < 2);
	
	my $name = shift @param;
	my $opt = shift @param;
  
	if(!$gets{$opt}) {
		my @cList = keys %gets;
		return "Unknown argument $opt, choose one of " . join(" ", @cList);
	}
 
  Log3 $name, 4, "TelegramKontakt_Get $name: Processing TelegramBot_Get( $opt )";
 
  my $answer = "No Data";
  if($opt eq 'LastMsg')
  {
    $answer = ReadingsVal($name,'LastMsg',$answer);
  }
  elsif ($opt eq 'LastMsgSend')
  {
    $answer = ReadingsVal($name,'LastMsgSend',$answer);
  }
	
	
	return $answer
}

1;

=pod
=item helper
=begin html

<a name="TelegramKontakt"></a>
<h3>dummy</h3>
<ul>

  Define a TelegramKontakt. A TelegramKontakt can take via <a href="#set">set</a> any messages that are send to the Kontakt if the State is inform.
  <br><br>

  <a name="TelegramKontaktdefine"></a>
  <b>Define</b>
  <ul>
    <code>define &lt;name&gt; TelegramKontakt</code>
    <br><br>

    Example:
    <ul>
      <code>define myvar TelegramKontakt</code><br>
      <code>set myvar message Hello World</code><br>
    </ul>
  </ul>
  <br>

  <a name="TelegramKontaktset"></a>
  <b>Set</b>
  <ul>
    <li><code>message Msg</code><br>
    Send  message Msg to contact. Message ist only send when STATE is set to 'inform'. If STATE is 'quiet' message will not be send.</li>
    
    <li> <code>quiet</code><br>
    Sets the contact in 'quiet'-mode. Messages are suppressed.</li>
    
    <li> <code>inform</code><br>
    Sets the contact in 'inform'-mode. Messages are send.</li>
  </ul>
  <br>

  <a name="TelegramKontaktget"></a>
  <b>Get</b> 
  <ul>
    <li><code>LastMsg </code><br>
    Get last message set (via set command,)</li>
    
    <li> <code>LastMsgSend </code><br>
    Get last message send to contact.</li>
  </ul>
  <br>

  <a name="TelegramKontaktttr"></a>
  <b>Attributes</b>
  <ul>
    <li>TelegramBot<br>
      Name of the TelegramBot that will be used to send message. Must be defines to send messages.</li>
      
    <li>TelegramId<br>
      Telegram UserId of the contact.  Must be defines to send messages.</li>

  </ul>
  <br>

</ul>

=end html

=begin html_DE

<a name="TelegramKontakt"></a>
<h3>dummy</h3>
<ul>

  Definiert eine TelegramKontaktvariable, der mit <a href="#set">set</a> message beliebige Nachrichten an den Kontakt versenden kann, wenn der STATE des Kontakts auf inform steht
  <br><br>

  <a name="TelegramKontaktdefine"></a>
  <b>Define</b>
  <ul>
    <code>define &lt;name&gt; TelegramKontakt</code>
    <br><br>

    Beispiel:
    <ul>
      <code>define myvar TelegramKontakt</code><br>
      <code>set message Hallo Welt</code><br>
    </ul>
  </ul>
  <br>

  <a name="TelegramKontaktset"></a>
  <b>Set</b>
  <ul>
    <li><code>message Msg</code><br>
    Sendt Nachricht Msg an den Kontakt. Die Nachricht wir nur verschickt, wenn der STATE auf 'inform' gesetzt ist. Wenn der STATE auf 'quiet' gesetzt wurde, wird die Nachricht nit versented.</li>
    
    <li> <code>quiet</code><br>
    Setzt den Kontakt in 'quiet'-modus. Nachrichten werden unterdrückt.</li>
    
    <li> <code>inform</code><br>
    Setzt den Kontakt in 'inform'-modus. Nachrichten werden gesendet.</li>
    
  </ul>
  <br>

  <a name="TelegramKontaktget"></a>
  <b>Get</b> 
  <ul>
    <li><code>LastMsg </code><br>
    Gibt die letzte Nachricht, die via set gesetzt wurde zurück.</li>
    
    <li> <code>LastMsgSend </code><br>
    Gibt die letzte Nachricht, die via set versendet wurde zurück.</li>
  </ul>
  <br>

  <a name="TelegramKontaktttr"></a>
  <b>Attributes</b>
  <ul>
    <li>TelegramBot<br>
      Name des TelegramBot der verwendet werden soll um Nachrichten zu versenden. Muss definiert sein um Nachrichten zu senden.</li>
      
    <li>TelegramId<br>
      Telegram UserId des Kontakts. Muss definiert sein um Nachrichten zu senden.</li>

  </ul>

</ul>

=end html_DE

=cut

