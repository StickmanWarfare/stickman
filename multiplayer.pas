unit multiplayer;

interface

uses sysutils, socketstuff, typestuff, D3DX9, windows, sha1, winsock2;
const
 TOKEN_RATE=10; //ezredm�sodpercenk�nti tokenek sz�ma
 TOKEN_LIMIT=2000; //bucket max m�rete
 PRIOR_NINCSPLOVES=0.5; //nem l�ttem r� pontosat
 PRIOR_NINCSLOVES=0.2; //egy�tal�n nem l�ttem r�
 PRIOR_AUTOBAN=0.5;//m�rmint a m�sik van aut�ban
 PRIOR_KAPOTT_CSAPATTARS=0.2;//az � .kapottprior-ja szorz�dik ezzel
 PRIOR_KAPOTT_ELLENSEG=0.5;//az � .kapottprior-ja szorz�dik ezzel
type

 TChat = record
  uzenet:string;
  glyph:integer;
 end;

 TMMOServerClient = class(TObject)
 private
  szerveraddr:TSockaddrIn;
  host,nev,jelszo:string;
  fegyver,fejcucc:integer;
  reconnect:cardinal;
  sock:TBufferedSocket;
  crypto:array [0..19] of byte; //kill csodacryptocucc
  sentmedals:array of word;
  laststatus:cardinal; //id� amikor utolj�ra lett st�tusz�zenet k�ldve
  procedure SendLogin(nev,jelszo:string;fegyver,fejrevalo,port,checksum:integer);
  procedure SendChat(uzenet:string);
  procedure SendStatus(x,y:integer);

  procedure NewCrypto;
  procedure SendKill(UID:integer);
  procedure SendMedal(medal:word);


  procedure ReceiveLoginok(frame:TSocketFrame);
  procedure ReceivePlayerlist(frame:TSocketFrame);
  procedure ReceiveChat(frame:TSocketFrame);
  procedure ReceiveKick(frame:TSocketFrame);
  procedure ReceiveWeather(frame:TSocketFrame);
  procedure ReceiveSendUDP(frame:TSocketFrame);
 public
  myport:integer; //�ltalam kijel�lt port
  myUID:integer;
  loggedin:boolean; //read only
  playersonserver:integer;
  chats:array [0..8] of TChat; //detto
  kicked:string;
  kickedhard:boolean;
  kills:integer;
  killscamping:integer; //readwrite
  killswithoutdeath:integer; // readwrite
  weather:single;
  constructor Create(ahost:string;aport:integer;anev,ajelszo:string;afegyver,afejcucc:integer);
  destructor Destroy;override;
  procedure Update(posx,posy:integer);
  procedure Chat(mit:string);
  procedure Killed(kimiatt:integer); //ez nem UID, hanem ppl index
  procedure Medal(c1,c2:char);
 end;

 //megjegyz�s: 20 b�jtba kell belef�rni egy ATM packethez, 68-ba kett�h�z
 TUDPFrame = class (TSocketFrame)
 public
  procedure WritePackedFloat(mit,scale:single);
  function ReadPackedFloat(scale:single):single;
  procedure WriteFloat(mit:single);
  function ReadFloat:single;
  procedure WriteVector(mit:TD3DXVector3);
  function ReadVector:TD3DXVector3;
  procedure WritePackedVector(mit:TD3DXVector3;scale:single);
  function ReadPackedVector(scale:single):TD3DXVector3;
  procedure WritePackedPos(mit:TD3DXVector3);
  function ReadPackedPos:TD3DXVector3;
 end;



  Thulla = record
   apos,vpos,gmbvec:TD3DXVector3;
   irany:single;
   animstate:single;
   mlgmb:byte;
   state:byte;
   enlottemle:boolean;
   index:integer;
  end;

 TMMOPeerToPeer = class(Tobject)
 private
  myfegyv:integer;
  sock:TUDPSocket;
  bucket:integer;
  lastsend:cardinal; //GTC
  roundrobinindex:integer;
  procedure ReceiveHandshake(port:word;frame:TUDPFrame);
  procedure ReceivePos(kitol:integer;frame:TUDPFrame);
  procedure ReceiveRongybaba(kitol:integer;frame:TUDPFrame);
  procedure CalculatePriorities(campos,lookatpos:TD3DXVector3);
  procedure SendFrame(frame:TUDPFrame;kinek:integer);
 public
  lovesek:array of Tloves; //kilotte: Index, k�v�lr�l olvasand� �s t�rlend�
  hullak:array of Thulla; //rongybab�k. Detto.
  constructor Create(port,fegyv:integer);
  destructor Destroy;override;
  procedure Update(posx,posy,posz,oposx,oposy,oposz,iranyx,iranyy:single;state:integer;
                   campos:TD3DXvector3;//a priorit�sokhoz
                   autoban:boolean; vanauto:boolean;
                   autopos:TD3DXVector3;autoopos:TD3DXVector3; autoaxes:array {0..2} of TD3DXVector3);
  procedure Killed(apos,vpos:TD3DXVector3;irany:single;state:byte;animstate:single;
                   mlgmb:byte;gmbvec:TD3DXVector3;
                   kimiatt:integer);
  procedure Loves(v1,v2:TD3DXVector3);
  procedure SendUDPToServer(frame:TUDPFrame);   //ez val�j�ban a multiscs, multip2p k�z�tti egy�ttm�k�d�shez kell.
 end;

var
 servername:string = 'stickman.hu';
 ppl:array of Tplayer;
 multisc:TMMOServerClient=nil;
 multip2p:TMMOPeerToPeer=nil;

implementation

const
 shared_key:array [0..19] of byte=($25,$25,$25,$25,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19);

 CLIENT_VERSION=PROG_VER;

 CLIENTMSG_LOGIN=1;
 {Login �zenet. Erre v�lasz: LOGINOK, vagy KICK
	int kliens_verzi�
	string n�v
	string jelsz�
	int fegyver
	int fejreval�
	char[2] port
	int checksum
  int langid
 }

 CLIENTMSG_STATUS=2;
 {Ennek az �zenetnek sok �rtelme nincs csak a kapcsolatot tartja fenn.
	int x
	int y
 }

 CLIENTMSG_CHAT=3;
 {Chat, ennyi.
	string uzenet
 }

 CLIENTMSG_KILLED=4;
 {Ha meg�lte a klienst valaki, ezt k�ldi.
	int UID
	char [20] crypto
 }

 CLIENTMSG_MEDAL=5;
 {A kliens med�lt k�r
	int med�l id
	char [20] crypto
 }

 SERVERMSG_LOGINOK=1;
 {
	int UID
	char [20] crypto
 }

 SERVERMSG_PLAYERLIST=2;
 {
 	int num
	num*
		char[4] ip
		char[2] port
		int uid
		string nev
		int fegyver
		int fejrevalo
		int killek
 }

 SERVERMSG_KICK=3;
 {
	char hardkick (bool igaz�b�l)
	string indok
 }

 SERVERMSG_CHAT=4;
 {
	string uzenet
 }

 SERVERMSG_WEATHER=5;
 {
	byte mi
 }

 SERVERMSG_SENDUDP=6;
 {
  int auth
 }

 P2PMSG_HANDSHAKE=1;
 {
	byte latlak
  int uid
 }

 P2PMSG_POS=2;

 P2PMSG_RONGYBABA=3;

procedure TMMOServerClient.SendLogin(nev,jelszo:string;fegyver,fejrevalo,port,checksum:integer);
var
 frame:TSocketFrame;
begin
 if (sock=nil) or loggedin then
  exit;
 frame:=TSocketFrame.Create;
 frame.WriteChar(CLIENTMSG_LOGIN);
 frame.WriteInt(CLIENT_VERSION);
 frame.WriteInt(nyelv);
 frame.WriteString(nev);
 frame.WriteString(jelszo);
 frame.WriteInt(fegyver);
 frame.WriteInt(fejrevalo);
 frame.WriteChar(port);
 frame.WriteChar(port shr 8);
 frame.WriteInt(checksum);
 sock.SendFrame(frame);
 frame.Free;
end;

procedure TMMOServerClient.SendChat(uzenet:string);
var
 frame:TSocketFrame;
begin
 if (sock=nil) or not loggedin then
  exit;
 frame:=TSocketFrame.Create;
 frame.WriteChar(CLIENTMSG_CHAT);
 frame.WriteString(uzenet);
 sock.SendFrame(frame);
 frame.Free;
end;

procedure TMMOServerClient.SendStatus(x,y:integer);
var
 frame:TSocketFrame;
begin
 if (sock=nil) or not loggedin then
  exit;
 frame:=TSocketFrame.Create;
 frame.WriteChar(CLIENTMSG_STATUS);
 frame.WriteInt(x);
 frame.WriteInt(y);
 sock.SendFrame(frame);
 frame.Free;
end;

procedure TMMOServerClient.NewCrypto;
var
i:integer;
 ujcrypto:TSHA1Digest;
begin
 for i:=0 to 19 do
  crypto[i]:=crypto[i] xor shared_key[i];
 ujcrypto:=SHA1Hash(@crypto[0],20);
 for i:=0 to 19 do
  crypto[i]:=ujcrypto[i];

end;


procedure TMMOServerClient.SendKill(UID:integer);
var
 frame:TSocketFrame;
 i:integer;
begin
 if (sock=nil) or not loggedin then
  exit;

 NewCrypto;

 frame:=TSocketFrame.Create;
 frame.WriteChar(CLIENTMSG_KILLED);
 frame.WriteInt(UID);
 for i:=0 to 19 do
  frame.WriteChar(crypto[i]);
 sock.SendFrame(frame);
 frame.Free;
end;

procedure TMMOServerClient.SendMedal(medal:word);
var
 frame:TSocketFrame;
 i:integer;
 ujcrypto:TSHA1Digest;
begin
 if (sock=nil) or not loggedin then
  exit;

 NewCrypto;

 frame:=TSocketFrame.Create;
 frame.WriteChar(CLIENTMSG_MEDAL);
 frame.WriteInt(medal);
 for i:=0 to 19 do
  frame.WriteChar(crypto[i]);
 sock.SendFrame(frame);
 frame.Free;
end;

procedure TMMOServerClient.ReceiveLoginok(frame:TSocketFrame);
var
i:integer;
begin
 loggedin:=true;
 myUID:=frame.ReadInt;
 for i:=0 to 19 do
  crypto[i]:=frame.ReadChar;
end;

procedure TMMOServerClient.ReceivePlayerlist(frame:TSocketFrame);
var
i,j,n:integer;
nev:string;
ip:DWORD;
port:WORD;
uid,fegyver,fejrevalo,killek:integer;
ujppl:array of Tplayer;
volt:boolean;
begin

 n:=frame.ReadInt;
 playersonserver:=n;
 setlength(ujppl,n);
 for i:=0 to n-1 do
 begin
  ip:=frame.ReadChar+
      (frame.ReadChar shl 8)+
      (frame.ReadChar shl 16)+
      (frame.ReadChar shl 24);
  port:=frame.ReadChar+
        (frame.ReadChar shl 8);
  uid:=frame.ReadInt;
  nev:=frame.ReadString;
	fegyver:=frame.ReadInt;
  fejrevalo:=frame.ReadInt;
  killek:=frame.ReadInt;

  if uid=myuid then
  begin
   uid:=0;
   kills:=killek;
   if killswithoutdeath=0 then
    killswithoutdeath:=kills;
   if killscamping=0 then
    killscamping:=kills;
  end;

  volt:=false;
  for j:=0 to high(ppl) do
   if ppl[j].net.UID=uid then
   begin
    ujppl[i]:=ppl[j];
    volt:=true;
    break;
   end;

  if not volt then
   ujppl[i]:=uresplayer;

  ujppl[i].net.ip:=ip;
  ujppl[i].net.port:=port;
  ujppl[i].net.UID:=uid;
  ujppl[i].pls.nev:=nev;
  ujppl[i].pls.fegyv:=fegyver;
  ujppl[i].pls.fejcucc:=fejrevalo;
  ujppl[i].pls.kills:=killek;
 end;
 setlength(ppl,n);
 for i:=0 to n-1 do
  ppl[i]:=ujppl[i];
 setlength(ujppl,0);
end;

procedure TMMOServerClient.ReceiveChat(frame:TSocketFrame);
var
i:integer;
begin
 for i:=high(chats) downto 1 do
  chats[i]:=chats[i-1];
 chats[0].uzenet:=frame.ReadString;
 chats[0].glyph:=frame.ReadInt;
end;

procedure TMMOServerClient.ReceiveKick(frame:TSocketFrame);
begin
 kickedhard:=frame.ReadChar=1;
 kicked:=frame.ReadString;
end;

procedure TMMOServerClient.ReceiveWeather(frame:TSocketFrame);
begin
 weather:=frame.ReadChar;
end;

procedure TMMOServerClient.ReceiveSendUDP(frame:TSocketFrame);
var
frame2:TUDPFrame;
begin
 frame2:=TUDPFrame.Create;
 frame2.WriteInt(ord('S') or (ord('T') shl 8) or (ord('C')  shl 16) or (ord('K') shl 24));
 frame2.WriteInt(myUID);
 frame2.WriteInt(frame.ReadInt);
 multip2p.SendUDPToServer(frame2);
 frame2.Free;
end;

constructor TMMOServerClient.Create(ahost:string;aport:integer;anev,ajelszo:string;afegyver,afejcucc:integer);
begin
 inherited Create;
 host:=ahost;
 myport:=aport;
 nev:=anev;
 jelszo:=ajelszo;
 fegyver:=afegyver;
 fejcucc:=afejcucc;

 sock:=nil;
 laststatus:=0;
 loggedin:=false;
 playersonserver:=0;
 kicked:='';
 kickedhard:=false;
 weather:=12;
 reconnect:=0;
 kills:=0;
 killscamping:=0;
 killswithoutdeath:=0;
end;

destructor TMMOServerClient.Destroy;
begin
 if sock<>nil then
 begin
  sock.Free;
  sock:=nil;
 end;

 inherited Destroy;
end;

procedure TMMOServerClient.Update(posx,posy:integer);
var
frame:TSocketFrame;
i:integer;
begin
 if sock=nil then
 begin
  if reconnect<GetTickCount then
  begin
   szerveraddr.sin_family := AF_INET;
   szerveraddr.sin_addr:=gethostbynamewrap(servername);
   szerveraddr.sin_port := htons(25252);
   sock:=TBufferedSocket.Create(CreateClientSocket(szerveraddr));
   SendLogin(nev,jelszo,fegyver,fejcucc,myport,checksum);
  end;
  exit;
 end;


 sock.Update;
 if sock.error<>0 then
 begin
  for i:=high(chats) downto 1 do
   chats[i]:=chats[i-1];
  chats[0].uzenet:='Cannot connect to server '+inttostr(sock.error);
  chats[0].glyph:=0;
  sock.Free;
  sock:=nil;
  loggedin:=false;
  reconnect:=GetTickCount+30000;
  exit;
 end;

 frame:=TSocketFrame.Create;
 while sock.RecvFrame(frame) do
 begin
  case frame.ReadChar of
   SERVERMSG_LOGINOK: ReceiveLoginok(frame);
   SERVERMSG_CHAT: ReceiveChat(frame);
   SERVERMSG_KICK: ReceiveKick(frame);
   SERVERMSG_PLAYERLIST: ReceivePlayerList(frame);
   SERVERMSG_WEATHER: ReceiveWeather(frame);
   SERVERMSG_SENDUDP: ReceiveSendUDP(frame);
  end;
 end;
 frame.Free;

 if laststatus<GetTickCount-3000 then
 begin
  laststatus:=GetTickCount;
  SendStatus(random(1000),random(1000));
 end;
end;

procedure TMMOServerClient.Chat(mit:string);
begin
 SendChat(copy(mit,2,256));
end;

procedure TMMOServerClient.Killed(kimiatt:integer); //ez nem UID, hanem ppl index
begin
 if kimiatt>-1 then
  SendKill(ppl[kimiatt].net.UID);
end;

procedure TMMOServerClient.Medal(c1,c2:char);
var
medalid:word;
i:integer;
begin
 medalid:=ord(c1) or (ord(c2) shl 8);
 for i:=0 to high(sentmedals) do
  if sentmedals[i]=medalid then
   exit;
 SendMedal(medalid);
 setlength(sentmedals,length(sentmedals)+1);
 sentmedals[high(sentmedals)]:=medalid;
end;

{
function packpos(mit:Tmukspos):Tpackedpos;
begin
 with result do
 begin
  pos.x:=packfloat(mit.pos.x,2500);
  pos.y:=packfloat(mit.pos.y,400);
  pos.z:=packfloat(mit.pos.z,2500);
  irany:=packfloatheavy(mit.irany,D3DX_PI);
  prior:=round(mit.prior);
  irany2:=packfloatheavy(mit.irany2,D3DX_PI);
  state:=mit.state;
  BG:=mit.BG;
 end;
end;
}

procedure TUDPFrame.WritePackedFloat(mit,scale:single);
var
 cucc:word;
begin
 cucc:=packfloat(mit,scale);
 WriteChar(cucc);
 WriteChar(cucc shr 8);
end;

function TUDPFrame.ReadPackedFloat(scale:single):single;
var
 cucc:word;
begin
 cucc:=ReadChar+(ReadChar shl 8);
 result:=unpackfloat(cucc,scale);
end;

procedure TUDPFrame.WriteFloat(mit:single);
var
 hack:integer absolute mit;
begin
 WriteInt(hack);
end;

function TUDPFrame.ReadFloat:single;
var
 hack:integer absolute result;
begin
 hack:=ReadInt;
end;

procedure TUDPFrame.WriteVector(mit:TD3DXVector3);
begin
 WriteFloat(mit.x);
 WriteFloat(mit.y);
 WriteFloat(mit.z);
end;

function TUDPFrame.ReadVector:TD3DXVector3;
begin
 with result do
 begin
  x:=ReadFloat;
  y:=ReadFloat;
  z:=ReadFloat;
 end;
end;

procedure TUDPFrame.WritePackedVector(mit:TD3DXVector3;scale:single);
begin
 WritePackedFloat(mit.x,scale);
 WritePackedFloat(mit.y,scale);
 WritePackedFloat(mit.z,scale);
end;

function TUDPFrame.ReadPackedVector(scale:single):TD3DXVector3;
begin
 with result do
 begin
  x:=ReadPackedFloat(scale);
  y:=ReadPackedFloat(scale);
  z:=ReadPackedFloat(scale);
 end;
end;

procedure TUDPFrame.WritePackedPos(mit:TD3DXVector3);
begin
 WritePackedFloat(mit.x,2500);
 WritePackedFloat(mit.y,400);
 WritePackedFloat(mit.z,2500);
end;

function TUDPFrame.ReadPackedPos:TD3DXVector3;
begin
 with result do
 begin
  x:=ReadPackedFloat(2500);
  y:=ReadPackedFloat(400);
  z:=ReadPackedFloat(2500);
 end;
end;

procedure TMMOPeerToPeer.ReceiveHandshake(port:word;frame:TUDPFrame);
var
i:integer;
flags:byte;
uid:integer;
kitol:integer;
begin
 flags:=frame.ReadChar;
 uid:=frame.ReadInt;
 kitol:=-1;
 for i:=0 to high(ppl) do
  if ppl[i].net.UID=uid then
  begin
   kitol:=i;
   break;
  end;

 if kitol<0 then
  exit;

 if not ppl[kitol].net.gothandshake then
 begin
  ppl[kitol].net.gothandshake:=true;      //�n kaptam t�le
  ppl[kitol].net.lasthandshake:=0; //hamar jelezz�nk neki vissza
 end;

 if flags<>0 then
  ppl[kitol].net.connected:=true;
 ppl[kitol].net.overrideport:=port;
end;


procedure TMMOPeerToPeer.ReceivePos(kitol:integer;frame:TUDPFrame);
var
gtc:cardinal;
lovesbyte:byte;
autobyte:byte;
i:integer;
volthgh:integer;
begin
 gtc:=gettickcount;
 with ppl[kitol] do
 begin
   pos.vpos:=pos.megjpos;
   pos.vseb:=pos.seb;
   pos.pos:=frame.ReadPackedPos;
   pos.seb:=frame.ReadPackedVector(1);

   pos.irany:= unpackfloatheavy(frame.ReadChar,D3DX_PI);
   pos.irany2:=unpackfloatheavy(frame.ReadChar,D3DX_PI);
   pos.state:=frame.ReadChar;
   net.kapottprior:=frame.ReadPackedFloat(1);

 {  lovesbyte:=(ppl[i].net.ploveseksz and 7) or
              ((ppl[i].net.loveseksz and 15) shl 3);}

   lovesbyte:=frame.ReadChar;
   volthgh:=length(lovesek);
   setlength(lovesek,length(lovesek)+(lovesbyte and 7)+((lovesbyte shr 3) and 15));

   for i:=0 to (lovesbyte and 7)-1 do
   begin
    lovesek[volthgh+i].pos:=frame.ReadVector;
    lovesek[volthgh+i].v2:=frame.ReadVector;
    lovesek[volthgh+i].kilotte:=kitol;
    lovesek[volthgh+i].fegyv:=pls.fegyv;
   end;

   volthgh:=volthgh+(lovesbyte and 7);

   for i:=0 to ((lovesbyte shr 3) and 15)-1 do
   begin
    d3dxvec3add(lovesek[volthgh+i].pos,pos.megjpos,
                D3DXVector3(0.7*sin(pos.irany),1.5,0.7*cos(pos.irany)));
    if 0<(pos.state and MSTAT_CSIPO) then
     lovesek[volthgh+i].pos.y:=lovesek[volthgh+i].pos.y-0.3;
    if 0<(pos.state and MSTAT_GUGGOL ) then
     lovesek[volthgh+i].pos.y:=lovesek[volthgh+i].pos.y-0.5;


    lovesek[volthgh+i].v2:=frame.ReadPackedVector(2500);
    lovesek[volthgh+i].kilotte:=kitol;
    lovesek[volthgh+i].fegyv:=pls.fegyv;
   end;

   if (lovesbyte and 128)<>0 then
   begin
    auto.enabled:=true;
    auto.vpos:=auto.pos;
    auto.vseb:=auto.seb;
    auto.vaxes:=auto.axes;
    net.vamtim:=net.amtim;

    autobyte:=frame.ReadChar;
    pls.autoban:=(autobyte and 1)<>0;
    auto.pos:=frame.ReadPackedPos;
    auto.seb:=frame.ReadPackedVector(1);
    for i:=0 to 2 do
     auto.axes[i]:=frame.ReadPackedVector(20);
    if D3DXVec3Lengthsq(auto.seb)<0.002*0.002 then
     auto.seb:=D3DXVector3Zero;
   net.avtim:=(gtc-net.aatim) div 10;
   if (net.avtim<=1) or (net.avtim>200) then
    net.avtim:=200;
   net.avtim:=net.avtim div 2;
   net.aatim:=gtc;
   net.amtim:=0;
   end
   else
   begin
    if auto.enabled then
     zeromemory(@auto,sizeof(auto));
    pls.autoban:=false;
   end;

   net.vtim:=(gtc-net.atim) div 10;
   if (net.vtim<=1) or (net.vtim>50) then
    net.vtim:=50;
   net.vtim:=net.vtim div 2;
   net.atim:=gtc;
   net.mtim:=0;
   net.connected:=true;
   net.gothandshake:=true;
 end;
end;


procedure TMMOPeerToPeer.ReceiveRongybaba(kitol:integer;frame:TUDPFrame);
begin
 setlength(hullak,length(hullak)+1);
 with hullak[high(hullak)] do
 begin
  apos:=frame.ReadVector;
  vpos:=frame.ReadVector;
  irany:=frame.ReadFloat;
  state:=frame.ReadChar;
  animstat:=frame.ReadFloat;
  mlgmb:=frame.ReadChar;
  gmbvec:=frame.ReadVector;
  enlottemle:=frame.ReadChar<>0;
  index:=kitol;
  ppl[kitol].pos.pos:=D3DXVector3Zero;
 end;
end;

procedure TMMOPeerToPeer.CalculatePriorities(campos,lookatpos:TD3DXVector3);
var
 i:integer;
 tmp:single;
begin
 for i:=0 to high(ppl) do
 begin
  if (ppl[i].net.UID=0) or (not ppl[i].net.connected) then
  begin
   ppl[i].net.prior:=0;
   continue;
  end;

  tmp:=tavpointline2(ppl[i].pos.megjpos,campos,lookatpos);
  if tmp<10 then
   tmp:=10;
  ppl[i].net.nekemprior:=10/tmp; //ez nem felhaszn�lva lesz, hanem elk�ldve. 0 �s 1 k�z�tt

  tmp:=0.5;
  if ppl[i].net.ploveseksz=0 then
   if ppl[i].net.loveseksz=0 then
    tmp:=tmp*PRIOR_NINCSLOVES
   else
    tmp:=tmp*PRIOR_NINCSPLOVES;

  if ppl[i].auto.enabled then
   tmp:=tmp*PRIOR_AUTOBAN;//m�rmint a m�sik van aut�ban

  if (ppl[i].pls.fegyv xor myfegyv)>127 then
   ppl[i].net.prior:=tmp+ppl[i].net.kapottprior*PRIOR_KAPOTT_CSAPATTARS
  else
   ppl[i].net.prior:=tmp+ppl[i].net.kapottprior*PRIOR_KAPOTT_ELLENSEG;
 end;
end;

constructor TMMOPeerToPeer.Create(port,fegyv:integer);
begin
 inherited Create;
 myfegyv:=fegyv;
 sock:=TUDPSocket.Create(port);
end;

destructor TMMOPeerToPeer.Destroy;
begin
 sock.Free;
 inherited Destroy;
end;

procedure TMMOPeerToPeer.SendFrame(frame:TUDPFrame;kinek:integer);
begin
 if ppl[kinek].net.overrideport=0 then
  sock.Send(frame.data,ppl[kinek].net.ip,ppl[kinek].net.port)
 else
  sock.Send(frame.data,ppl[kinek].net.ip,ppl[kinek].net.overrideport);
end;

procedure TMMOPeerToPeer.SendUDPToServer(frame:TUDPFrame);
begin
 sock.Send(frame.data,multisc.szerveraddr.sin_addr.S_addr,25252);
end;


procedure TMMOPeerToPeer.Update(posx,posy,posz,oposx,oposy,oposz,iranyx,iranyy:single;
                   state:integer;campos:TD3DXvector3;//a priorit�sokhoz
                   autoban:boolean; vanauto:boolean;
                   autopos:TD3DXVector3;autoopos:TD3DXVector3; autoaxes:array {0..2} of TD3DXVector3);
var
i,j:integer;
leszkikuldjon:boolean;
frame:TUDPFrame;
arr:TDynByteArray;
ip:DWORD;
port:WORD;
kitoljott:integer;
lookatpos:TD3DXVector3;
lovesbyte:byte;
autobyte:byte;
gtc:integer;
begin
 while sock.Recv(arr,ip,port) do
 begin
  frame:=TUDPFrame.CreateFromData(arr);
  kitoljott:=-1;
  for i:=0 to high(ppl) do
   if (ip=ppl[i].net.ip) and ((port=ppl[i].net.port) or (port=ppl[i].net.overrideport)) then
   begin
    kitoljott:=i;
    break;
   end;
  case frame.ReadChar of
   P2PMSG_HANDSHAKE: ReceiveHandshake(port,frame);
   P2PMSG_POS: if kitoljott>=0 then ReceivePos(kitoljott,frame);
   P2PMSG_RONGYBABA: if kitoljott>=0 then ReceiveRongybaba(kitoljott,frame);
  end;

  frame.Free;
 end;

 if length(ppl)=0 then
  exit;

 gtc:=GetTickCount;
 for i:=0 to high(ppl) do
  if not ppl[i].net.connected and
     (ppl[i].net.lasthandshake<gtc-2000) then
  begin
   frame:=TUDPFrame.Create;
   frame.WriteChar(P2PMSG_HANDSHAKE);
   if ppl[i].net.gothandshake then
    frame.WriteChar(1)
   else
    frame.WriteChar(0);
   frame.WriteInt(multisc.myUID);
   SendFrame(frame,i);
   frame.Free;
   ppl[i].net.lasthandshake:=gtc;
  end;

 D3DXVec3Scale(lookatpos,D3DXVector3(sin(iranyx)*cos(iranyy),sin(iranyy),cos(iranyx)*cos(iranyy)),300);
 D3DXVec3Add(lookatpos,lookatpos,campos);
 D3DXVec3Subtract(autoopos,autopos,autoopos);

 CalculatePriorities(campos,lookatpos);
 bucket:=bucket+integer(GetTickCount-lastsend)*TOKEN_RATE;
 lastsend:=GetTickCount;
 if bucket<-TOKEN_LIMIT then //valami WTF t�rt�nt
  bucket:=0;
 if bucket>TOKEN_LIMIT then
  bucket:=TOKEN_LIMIT;

 if (roundrobinindex>high(ppl)) or (roundrobinindex<0) then
  roundrobinindex:=0;

 i:=roundrobinindex;

 leszkikuldjon:=false;
 while bucket>0 do
 begin
  if ppl[i].net.priorbucket<=0 then
  begin
   if ppl[i].net.prior>0 then
   begin
    ppl[i].net.priorbucket:=ppl[i].net.priorbucket+ppl[i].net.prior;
    leszkikuldjon:=true;
   end;
  end
  else
  begin
   //send packet, prior-=1, bucket-=b�jtok
   frame:=TUDPFrame.Create;
   frame.WriteChar(P2PMSG_POS);

   frame.WritePackedPos(D3DXVector3(posx,posy,posz));

   frame.WritePackedVector(D3DXVector3(posx-oposx,posy-oposy,posz-oposz),1);

   frame.WriteChar(packfloatheavy(iranyx,D3DX_PI));
   frame.WriteChar(packfloatheavy(iranyy,D3DX_PI));
   frame.WriteChar(state);
   frame.WritePackedFloat(ppl[i].net.nekemprior,1);

   lovesbyte:=(ppl[i].net.ploveseksz and 7) or
              ((ppl[i].net.loveseksz and 15) shl 3);
   if vanauto then lovesbyte:=lovesbyte or 128;

   frame.WriteChar(lovesbyte);

   for j:=0 to ppl[i].net.ploveseksz-1 do
   begin
    frame.WriteVector(ppl[i].net.plovesek[j].pos);
    frame.WriteVector(ppl[i].net.plovesek[j].v2);
   end;

   for j:=0 to ppl[i].net.loveseksz-1 do
   begin
    frame.WritePackedVector(ppl[i].net.lovesek[j].v2,2500);
   end;

   ppl[i].net.ploveseksz:=0;
   ppl[i].net.loveseksz:=0;

   if vanauto then
   begin
    autobyte:=0;
    if autoban then
     autobyte:=autobyte or 1;
    frame.WriteChar(autobyte);
    frame.WritePackedPos(autopos);
    frame.WritePackedVector(autoopos,1);
    for j:=0 to 2 do
     frame.WritePackedVector(autoaxes[j],20);
   end;

   SendFrame(frame,i);

   bucket:=bucket-frame.cursor-28;
   ppl[i].net.priorbucket:=ppl[i].net.priorbucket-1;
   ppl[i].net.prior:=0; //ebben a k�rben t�bet nem kap.
   frame.Free;
  end;

  inc(i);
  if i>high(ppl) then
   i:=0;
  if i=roundrobinindex then
   if not leszkikuldjon then
    break
   else
    leszkikuldjon:=false;
 end;
 roundrobinindex:=i;
end;

procedure TMMOPeerToPeer.Killed(apos,vpos:TD3DXVector3;irany:single;state:byte;animstate:single;
                   mlgmb:byte;gmbvec:TD3DXVector3;
                   kimiatt:integer);
var
 frame,framespec:TUDPFrame;
 indexek:array of integer;
 i,j,tmp:integer;
begin
 frame:=TUDPFrame.Create;
 frame.WriteChar(P2PMSG_RONGYBABA);
 frame.WriteVector(apos);
 frame.WriteVector(vpos);
 frame.WriteFloat(irany);
 frame.WriteChar(state);
 frame.WriteFloat(animstate);
 frame.WriteChar(mlgmb);
 frame.WriteVector(gmbvec);

 framespec:=TUDPFrame.CreateFromData(frame.data);
 framespec.cursor:=frame.cursor;

 frame.WriteChar(0);
 framespec.WriteChar(1);

 setlength(indexek,length(ppl));
 for i:=0 to high(ppl) do
  indexek[i]:=i;

 if kimiatt>=0 then
 begin
  indexek[kimiatt]:=0;
  indexek[0]:=kimiatt;
 end;

 //lenne mit optimaliz�lni de minek.
 for i:=1 to high(ppl) do
  for j:=i+1 to high(ppl) do
   if TavPointPointSq(ppl[indexek[i]].pos.megjpos,apos)>TavPointPointSq(ppl[indexek[j]].pos.megjpos,apos) then
   begin
    tmp:=indexek[i];
    indexek[i]:=indexek[j];
    indexek[j]:=tmp;
   end;

 if kimiatt>=0 then
 begin
  SendFrame(framespec,indexek[0]);
  for i:=1 to high(ppl) do
  if ppl[indexek[i]].net.connected then
   SendFrame(frame,indexek[i]);
 end
 else
  for i:=0 to high(ppl) do
  if ppl[indexek[i]].net.connected then
   SendFrame(frame,indexek[i]);
 frame.Free;
end;

procedure TMMOPeerToPeer.Loves(v1,v2:TD3DXVector3);
var
i:integer;
j:integer;
begin
 for i:=0 to high(ppl) do
 if ppl[i].net.connected then
 begin
  if (TavPointLine2(ppl[i].pos.megjpos,v1,v2)<0) or
     (myfegyv=FEGYV_LAW) or (myfegyv=FEGYV_NOOB) or (myfegyv=FEGYV_X72) then
  begin
   if ppl[i].net.ploveseksz<7 then
   begin
    j:=ppl[i].net.ploveseksz;
    ppl[i].net.plovesek[j].pos:=v1;
    ppl[i].net.plovesek[j].v2:=v2;
    ppl[i].net.ploveseksz:=ppl[i].net.ploveseksz+1;
   end;
  end
  else
  begin
   if ppl[i].net.loveseksz<15 then
   begin
    j:=ppl[i].net.loveseksz;
    ppl[i].net.lovesek[j].v2:=v2;
    ppl[i].net.loveseksz:=ppl[i].net.loveseksz+1;
   end;
  end;
 end;

end;

end.
