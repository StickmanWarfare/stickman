unit BotGroups;

interface

uses
  math,
  D3DX9,
  Direct3D9,
  muksoka,
  fizika,
  multiplayer,
  mmsystem,
  fegyverek,
  ojjektumok,
  Typestuff,
  Utils,
  Windows;

const
  BOT_DUMMY = 0;
  BOT_NORMAL = 1;
  BOT_PRO = 2;
  BOT_EASY = 3;
  BOT_PATROL = 4;
  BOT_BEACH = 5;

type
  TBotMode = BOT_DUMMY..BOT_BEACH;

  OwnProps =
  record
    id: Integer;
    botMode: TBotMode;
    respawnPos: TD3DXVector3;
    respawnRad: Cardinal;
    fegyv: Byte;
    //
    baseSpeed: Single;
    baseAccuracy: Single;
    baseVisibilityRadius: Single;
    baseLovesCooldown: Single; //tick num
    baseReactionTime: Cardinal; //tick num
    baseRespawnTime: Cardinal; //tick num
    baseInvulTime: Cardinal; //tick num
  end;

  ForeignProps =
  record
    playerPos: TD3DXVector3;
    playerFegyv: Byte;
    playerHalott: boolean;
    playerMatWorld: TD3DXMatrix;
    allies: array of TD3DXVector3;
    enemies: array of TD3DXVector3;
  end;

  State =
  record          
    pos: TD3DXVector3;
    mozgas: TD3DXVector3;
    lastMozgas: TD3DXVector3;
    rotateX, rotateY: Single;
    lastMuks: TMuksoka;
    targetVec: TD3DXVector3; //target labanal
    isDead: Integer; //tick num, resets to baseRespawnTime, -1 means alive
    isInvul: Integer; //tick num, resetrs to baseInvulTime, -1 means not invul
    isMoving: boolean;
    //
    actionStart: Cardinal; //tick
    actionLength: Cardinal; //tick num
    checkTargets: Cardinal; //tick num, checks on zero, resets to baseReactionTime
    canShootCd: Single; //tick num, resets to baseLovesCooldown
    aiming: boolean;
  end;

  TBot = class
  private
    ownProps: OwnProps;
    foreignProps: ForeignProps;
    state: State;
    //
    function hasOjjektumCollide: boolean;
    procedure resetMozgas;
    procedure applyMozgas;
    function findTarget: TD3DXVector3;
    procedure facePoint(_pos: TD3DXVector3);
    function canSeePoint(_pos: TD3DXVector3): boolean;
    procedure shootPoint(_pos: TD3DXVector3);
    procedure putRagdoll(_pos: TD3DXVector3; forceRajtam: TD3DXVector3);
  public
    constructor Create(_id: Integer; _botMode: TBotMode; _fegyv: Byte; _pos: TD3DXVector3; _rad: Cardinal);
    procedure Draw(mukso: TMuksoka; fegyver: TFegyv; campos: TD3DXVector3);
    //
    function getFegyv: BYTE;
    function getIsDead: boolean;
    function getFegyvMatr: TD3DMatrix;
    //
    procedure doLogic;
    procedure passInfo(_playerHalott: boolean; _playerFegyv: Byte; _playerPos: TD3DXVector3; _playerMatWorld: TD3DXMatrix; _bots: array of TBot);
    procedure collideProjectile(loves: TLoves);
  end;

  TBotArray = array of TBot;

  TBotGroup = class
  private
    id: Cardinal;
    size: Cardinal;
  public
    botMode: TBotMode;
    bots: TBotArray;
    fegyvs: array of Byte;
    spawnpos: TD3DXVector3;
    spawnrad: Cardinal;
    maxSize: Cardinal;
    team: string;
    constructor Create(
      _id: Cardinal;
      _maxSize: Cardinal;
      _team: string;
      _botMode: TBotMode;
      _spawnpos: TD3DXVector3;
      _spawnrad: Cardinal
    );
    //optional TODO: destructor Destroy();
    function Add(bot: TBot): Integer;
    function AddFegyv(fegyv: Byte): Integer;
    //TODO: function Remove(index: Integer): Boolean;
    //TODO: function RemoveById(id: Integer): Boolean;
    //TODO: function findById(id: Integer): Integer; //TODO: move to Utils.pas
  end;

implementation


///////////////////////
//   HELPERS FUNCS   //
///////////////////////

procedure _addHudMessage(input:string;col:longword;f:word = 500);
var
  i:byte;
begin
  for i:=high(hudMessages) downto low(hudMessages) + 1 do
    hudMessages[i]:=hudMessages[i - 1];

  i:=low(hudMessages);

  hudMessages[i]:=THUDMessage.create(input, col, f);
end;

procedure _addrongybaba(apos, vpos, gmbvec:TD3DXVector3;fegyv, mlgmb:byte;ID:cardinal;muks:TMuksoka;matWorld:TD3DMatrix);
var
  szin:cardinal;
begin
  // apos.y:=apos.y+0.5;

  if rbszam >= 50 then exit;
  inc(rbszam);
  //rongybabak[rbszam]:=nil;
  if fegyv > 127 then szin:=techszin else szin:=gunszin;
  rongybabak[rbszam]:=TRongybaba.Create(matWorld, muks, apos, vpos, gmbvec, mlgmb, ID, szin);

  //playsound(9 + halalhorg, false, integer(timegettime) + random(10000), true, rongybabak[rbszam].gmbk[10]);
  //halalhorg:=(halalhorg + 1) mod 3;
end;

function _vanottvalami(xx:single;var yy:single;zz:single):boolean; //copy
const
  szor = 2;
var
  i:integer;
  tav:single;
begin
  result:=false;

  for i:=0 to high(posrads) do
    with posrads[i] do
    begin

      tav:=sqr(posx - xx) + sqr(posz - zz);
      if tav > sqr(raddn) then continue;

      if tav < sqr(radd) then
        tav:=0
      else
      begin
        tav:=sqrt(tav);
        if tav<(radd + raddn) * 0.5 then
          tav:=sqr((tav - radd) / (raddn - radd)) * 2
        else
          tav:=1 - sqr((raddn - tav) / (raddn - radd)) * 2;
      end;
      yy:=posy * (1 - tav) + yy * tav;
      result:=true;
    end;
end;

function _advwove(xx, zz:single):single; //copy
var
  ay:single;
begin
  if (xx < -10000) or (xx > 10000) or (zz < -10000) or (zz > 10000) then
  begin
    result:=0;
    exit;
  end;
  ay:=wove(xx, zz);
  _vanottvalami(xx, ay, zz);
  result:=ay;
end;

function _raytestlvl(
  v1, v2:TD3DXVector3;
  hany:integer;
  var v3:TD3DXVector3
):boolean; //copy
var
  k:integer;
  v4:TD3DXVector3;
begin
  v4:=v1;
  for k:=0 to hany do
  begin
    v3:=v4;
    d3dxvec3lerp(v4, v1, v2, k / (hany + 1));
    try
      if _advwove(v4.x, v4.z) > v4.y then
      begin
        result:=true;exit;
        v3:=v4;
      end;
    except
      v3:=v2;result:=false;exit;
    end;
  end;

  result:=false;
end;

function _tavPointPoint(Point1, point2:TD3DXvector3):single;
var
  Vec:TD3DXVector3;
begin

  Vec.X:=Point2.X - Point1.X;
  Vec.Y:=Point2.Y - Point1.Y;
  Vec.Z:=Point2.Z - Point1.Z;

  result:=sqrt(Vec.X * Vec.X + Vec.Y * Vec.Y + Vec.Z * Vec.Z);
end;

function _fegyvercooldown(mi:byte): Single;
begin
  case mi of
    FEGYV_M4A1:result:= 1 / 7.44;
    FEGYV_M82A1:result:= 1;
    FEGYV_LAW:result:= 3; //ugyse lesznek vele
    FEGYV_MPG:result:= 1 / 6;
    FEGYV_QUAD:result:= 1 / 7.93;
    FEGYV_NOOB:result:= 3; //ezzel se
    FEGYV_X72:result:= 1 / 3; //ezzel se
    FEGYV_MP5A3:result:= 1 / 6; //lassabb mert pontos marad
    FEGYV_BM3:result:= 1 / 1.2;
    FEGYV_HPL:result:= 1;
    FEGYV_GUNSUPP:result:= 1 / 1.5; //ezzel se elvileg
    FEGYV_TECHSUPP:result:= 1 / 7.44; //ezzel se elvileg
  else
    result:= -1;
  end;
end;

function _meglove(
  gmbk:Tgmbk;
  kapcsk:Tkapcsk;
  lin, ir:Td3DVector;
  fegyvvst:single;
  matWorld: TD3DXMatrix
):integer;
var
  i, j:integer;
  dst:single;
  tmp, tmp2:TD3DXvector3;
  transgmbk:TGmbk;
begin

  D3DXVec3TransformCoordArray(@transgmbk[0], sizeof(gmbk[0]), @gmbk[0], sizeof(gmbk[0]), matWorld, 11);
  dst:=10000;
  for i:=0 to 9 do
    if tavpointline(transgmbk[i], lin, ir, tmp, dst) then
      if dst<(vst + fegyvvst) then
      begin
        result:=i;
        exit;
      end;

  if tavpointline(transgmbk[10], lin, ir, tmp, dst) then
    if dst<(fejvst + fegyvvst) then
    begin
      result:=10;
      exit;
    end;

  for j:=0 to 9 do
  begin
    dst:=1000;
    if tavlineline(transgmbk[kapcsk[j, 0]], transgmbk[kapcsk[j, 1]], lin, ir, tmp, tmp2, dst) then
      if dst<(vst + fegyvvst) then
      begin
        result:=kapcsk[j, 0];
        exit;
      end;
  end;
  result:= -1;
end;

function _getRandomPos(
  base:TD3DXvector3;
  radius:Cardinal
):TD3DXvector3;
var
  tmp:TD3DXvector3;
begin
   tmp.x := base.x + random(radius) - radius div 2;
   tmp.y := base.y;
   tmp.z := base.z + random(radius) - radius div 2;
   result := tmp;
end;

///////////////////////
//       TBOT       //
///////////////////////

constructor TBot.Create(
  _id: Integer;
  _botMode: TBotMode;
  _fegyv: Byte;
  _pos: TD3DXVector3;
  _rad: Cardinal
);
begin
  //Init OwnProps
  ownProps.id := _id;
  ownProps.botMode := _botMode;
  ownProps.respawnPos := _pos;
  ownProps.respawnRad := _rad;
  ownProps.fegyv := _fegyv;
  //
  ownProps.baseSpeed := 0.08;
  ownProps.baseAccuracy := (random(35) + 15) / 100;
  ownProps.baseVisibilityRadius := 50;
  ownProps.baseReactionTime := random(30) + 60;
  ownProps.baseLovesCooldown := _fegyvercooldown(_fegyv) * 1.2;
  ownProps.baseRespawnTime := 500;
  ownProps.baseInvulTime := 100;

  //Init State
  state.pos := _getRandomPos(ownProps.respawnPos, ownProps.respawnRad);
  state.mozgas := D3DXVector3(0, 0, 0);
  //state.lastMozgas
  state.rotateX := 0;
  state.rotateY := random(628)/100; //almost 2pi
  //state.lastMuks
  state.targetVec := D3DXVector3(0, 0, 0);
  state.isDead := -1;
  state.isInvul := -1;
  state.isMoving := FALSE;
  //
  state.actionStart := getTickCount; //tick
  state.actionLength := ownProps.baseReactionTime;
  state.checkTargets := ownProps.baseReactionTime;
  //state.canShootCd
  state.aiming := TRUE;
end;

procedure
  TBot.Draw(mukso: TMuksoka; fegyver: TFegyv; campos: TD3DXVector3);
var
  szin: Cardinal;
  matWorld, matWorld2: TD3DMatrix;
  //matb: TD3DMatrix;
  animstate: Byte;
  isFalling: boolean;
begin
  state.isMoving := (state.mozgas.x <> 0) or (state.mozgas.z <> 0);
  isFalling := _advwove(state.pos.x, state.pos.z) < state.pos.y - 1; //above map height
  if ownProps.fegyv < 128 then szin := gunszin else szin := techszin;

  D3DXMatrixRotationY(matWorld2, state.rotateY + D3DX_PI);
  //D3DXMatrixRotationX(matb, rotateX);                     //

  //D3DXMatrixMultiply(matb, matb, matWorld2);              //

  D3DXMatrixTranslation(matWorld, state.pos.x, state.pos.y, state.pos.z);
  D3DXMatrixMultiply(matWorld2, matWorld2, matWorld);

  //D3DXMatrixTranslation(matWorld, pos.x, pos.y, pos.z);    //
  //D3DXMatrixMultiply(matb, matb, matWorld);                //

  if state.isMoving and not isFalling then
    animstate := MSTAT_FUT
  else
    animstate := MSTAT_ALL;

  mukso.jkez:=fegyver.jkez(ownProps.fegyv, animstate, clipszogy(state.rotateX));
  mukso.bkez:=fegyver.bkez(ownProps.fegyv, animstate, clipszogy(state.rotateX));
  if not state.isMoving or isFalling then mukso.Stand(FALSE); //ha true gugol.
  if state.isMoving and not isFalling then
    mukso.Runn((timegettime mod 1000) / 1000, state.aiming);

  state.lastMuks := mukso;
  mukso.Render(szin, matWorld2, campos);
end;

function TBot.GetFegyvMatr(): TD3DMatrix;
var
  matWorld, matWorld2, mat2:TD3DMatrix;
begin
  D3DXMatrixRotationY(matWorld2, state.rotateY + D3DX_PI);
  D3DXMatrixRotationX(mat2, clipszogy(state.rotateX));
  D3DXMatrixMultiply(matWorld2, mat2, matWorld2);

  if (ownProps.fegyv = FEGYV_HPL) and state.aiming then
      D3DXMatrixTranslation(matWorld, -0.05, 0.02, -0.11)
  else if (ownProps.fegyv = FEGYV_M82A1) and not state.aiming then
      D3DXMatrixTranslation(matWorld, -0.05, -0.05, 0.15)
  else if (ownProps.fegyv = FEGYV_BM3) and state.aiming then
      D3DXMatrixTranslation(matWorld, -0.05, -0.05, 0.06)
  else if (ownProps.fegyv = FEGYV_BM3) and not state.aiming then
      D3DXMatrixTranslation(matWorld, -0.05, 0.01, -0.08)
  else if (ownProps.fegyv = FEGYV_LAW) then
      D3DXMatrixTranslation(matWorld, 0.05, 0, 0)
  else if (ownProps.fegyv = FEGYV_H31_T) or (ownProps.fegyv = FEGYV_H31_G) then
      D3DXMatrixTranslation(matWorld, 0.05, 0, 0)
  else if (ownProps.fegyv = FEGYV_QUAD) and state.aiming then
      D3DXMatrixTranslation(matWorld, -0.00, -0.1, -0.03)
  else
      D3DXMatrixTranslation(matWorld, -0.05, 0, 0);

   //if (ppl[mi].pos.state and MSTAT_MASK) = 8 then
   // D3DXMatrixTranslation(matWorld, -0.2, 0.2, -0.1);


  D3DXMatrixMultiply(matWorld2, matWorld, matWorld2);

  if not state.aiming then
    D3DXMatrixTranslation(matWorld, state.pos.x, state.pos.y + 1.2, state.pos.z)
  else
    D3DXMatrixTranslation(matWorld, state.pos.x, state.pos.y + 1.5, state.pos.z);

  D3DXMatrixMultiply(matWorld, matWorld2, matWorld);

  result:=matWorld;
end;

procedure TBot.resetMozgas;
begin
  state.mozgas := D3DXVector3(0, 0, 0);
end;

procedure TBot.applyMozgas;
begin
  D3DXVec3Add(state.pos, state.pos, state.mozgas);
  if (state.mozgas.x <> 0) or (state.mozgas.z <> 0) then
    state.lastMozgas := D3DXVector3(state.mozgas.x, 0, state.mozgas.z);
end;

function TBot.hasOjjektumCollide(): boolean;
var
  ojjektumIndex, ojjektumInstanceIndex: Integer;
  tmpVec: TD3DXVector3;
  distance: Single;
label skipEgyet;
begin
  result := FALSE;
  tmpVec := state.mozgas;
  tmpVec.y := state.mozgas.y + 0.1;
  if state.mozgas.x <> 0 then
    tmpVec.x := ceil(state.mozgas.x) + (sin(state.rotateY) * 2);
  if state.mozgas.z <> 0
    then tmpVec.z := ceil(state.mozgas.z) + (cos(state.rotateY) * 2);

  D3DXVec3Add(tmpVec, state.pos, tmpVec);
  for ojjektumIndex := 0 to high(ojjektumnevek) do
    for ojjektumInstanceIndex := 0 to ojjektumarr[ojjektumIndex].hvszam - 1 do
    begin
      distance :=
        tavPointPoint(state.pos, ojjektumarr[ojjektumIndex].holvannak[ojjektumInstanceIndex]);
      if distance > 50 then goto skipEgyet;  
      if ojjektumarr[ojjektumIndex].raytestbol(state.pos, tmpVec, ojjektumInstanceIndex, COLLISION_SOLID) then
      begin
        result := TRUE;
        exit;
      end;
      skipEgyet:
    end;
end;

function TBot.canSeePoint(_pos: TD3DXVector3): boolean;
var
  fejem, junk: TD3DXVector3;
  ojjektumIndex, ojjektumInstanceIndex: Integer;
label skip;
begin
  fejem := state.pos;
  fejem.y := fejem.y + 1.5;

  //check against terrain
  result := not _raytestlvl(fejem, _pos, 10, junk);
  if not result then exit;

  //check against ojjektumok
  for ojjektumIndex := 0 to high(ojjektumnevek) do
    for ojjektumInstanceIndex := 0 to ojjektumarr[ojjektumIndex].hvszam - 1 do
    begin

      result :=
        ojjektumarr[ojjektumIndex].raytestbol(fejem, _pos, ojjektumInstanceIndex, COLLISION_BULLET);

      if result then
      begin
        result := FALSE;
        exit;
      end;

      skip:
    end;

    result := TRUE;
end;

//optional TODO: remove code duplication
function TBot.findTarget(): TD3DXVector3;
const
  inaccuracyModifier = 2;
var
  tmpVec1, tmpVec2, inaccuracy: TD3DXVector3;
  botIndex: Integer;
  isGun, amGun, isAlly, isInaccurate: boolean;
label skipbots;
begin
  result := D3DXVector3(0, 0, 0);
  inaccuracy := D3DXVector3(
    -inaccuracyModifier + random(inaccuracyModifier + 1),
    0,
    -inaccuracyModifier + random(inaccuracyModifier + 1)
  );
  D3DXVec3Scale(inaccuracy, inaccuracy, 0.1);
  amGun := ownProps.fegyv < 128;

  //pick enemy bot
  if length(foreignProps.enemies) <= 0 then goto skipbots;
  botIndex := low(foreignProps.enemies) + random(length(foreignProps.enemies));
  tmpVec1 := foreignProps.enemies[botIndex];
  tmpVec1.y := tmpVec1.y + 1.5; //fejre lovok

  //apply inaccuracy
  tmpVec2 := D3DXVector3Zero;
  isInaccurate := random(10) > 7;
  if isInaccurate then
    D3DXVec3Add(tmpVec2, tmpVec1, inaccuracy)
  else
    tmpVec2 := tmpVec1;

  if canSeePoint(tmpVec2) then
  begin
    result := tmpVec2;
    exit;
  end;

  skipbots:
  //exit; //DONT SHOOT ME

  //should target player
  if foreignProps.playerHalott then exit;
  if tavPointPoint(foreignProps.playerPos, state.pos) > ownProps.baseVisibilityRadius then exit;
  isGun := foreignProps.playerFegyv < 128;
  isAlly := isGun = amGun;
  if isAlly then exit;

  tmpVec1 := foreignProps.playerPos;
  tmpVec1.y := tmpVec1.y + 1.5; //fejre lovok

  //apply inaccuracy
  tmpVec2 := D3DXVector3Zero;
  isInaccurate := random(10) > 7;
  if isInaccurate then
    D3DXVec3Add(tmpVec2, tmpVec1, inaccuracy)
  else
    tmpVec2 := tmpVec1;

  if canSeePoint(tmpVec2) then
    result := tmpVec2;

end;

procedure TBot.facePoint(_pos: TD3DXVector3);
var
  xDst, zDst: Single;
begin
  zDst := state.pos.z - _pos.z;
  xDst := state.pos.x - _pos.x;
  state.rotateY := arctan2(xDst, zDst) + D3DX_PI;
end;

procedure TBot.shootPoint(_pos: TD3DXVector3);
var
  tmpVec: TD3DXVector3;
begin
  D3DXVec3Subtract(tmpVec, _pos, D3DXVector3(state.pos.x, state.pos.y + 1.5, state.pos.z));
  D3DXVec3Scale(tmpVec, tmpVec, 100);
  D3DXVec3Add(tmpVec, tmpVec, D3DXVector3(state.pos.x, state.pos.y + 1.5, state.pos.z));

  _raytestlvl(D3DXVector3(state.pos.x, state.pos.y + 1.5, state.pos.z), tmpVec, 500, tmpVec);

  //TODO: collide ojjektumok

  setlength(multip2p.lovesek, length(multip2p.lovesek) + 1);
  multip2p.lovesek[high(multip2p.lovesek)].fegyv := ownProps.fegyv;
  multip2p.lovesek[high(multip2p.lovesek)].pos := state.pos;
  multip2p.lovesek[high(multip2p.lovesek)].pos.y := state.pos.y + 1.5;
  multip2p.lovesek[high(multip2p.lovesek)].v2 := tmpVec;
  multip2p.lovesek[high(multip2p.lovesek)].kilotte:= -2;
  state.canShootCd := ownProps.baseLovesCooldown;
end;

procedure TBot.collideProjectile(loves: TLoves);
var
  isGun, amGun, isHit: boolean;
  matWorld, matWorld2 :TD3DMatrix;
  muks: TMuksoka;
begin
  if state.isDead > -1 then exit;
  if state.isInvul > -1 then exit;

  amGun := ownProps.fegyv < 128;
  isGun := loves.fegyv < 128;
  if isGun = amGun then exit;

  muks := state.lastMuks;

  isHit := FALSE;

  D3DXMatrixRotationY(matWorld2, state.rotateY + D3DX_PI);
  D3DXMatrixTranslation(matWorld, state.pos.x, state.pos.y, state.pos.z);
  D3DXMatrixMultiply(matWorld2, matWorld2, matWorld);
  case loves.fegyv of
    FEGYV_M4A1:isHit:=-1 < _meglove(muks.gmbk, muks.kapcsk, loves.pos, loves.v2, 0.033, matWorld2);
    FEGYV_M82A1:isHit:=-1 < _meglove(muks.gmbk, muks.kapcsk, loves.pos, loves.v2, 0.065, matWorld2);
    FEGYV_MPG:isHit:=-1 < _meglove(muks.gmbk, muks.kapcsk, loves.pos, loves.v2, 0.15, matWorld2);
    FEGYV_QUAD:isHit:=-1 < _meglove(muks.gmbk, muks.kapcsk, loves.pos, loves.v2, 0.2, matWorld2);
    FEGYV_MP5A3:isHit:=-1 < _meglove(muks.gmbk, muks.kapcsk, loves.pos, loves.v2, 0.02, matWorld2);
    FEGYV_BM3:isHit:=-1 < _meglove(muks.gmbk, muks.kapcsk, loves.pos, loves.v2, 0.085, matWorld2);
    FEGYV_BM3_2:isHit:=-1 < _meglove(muks.gmbk, muks.kapcsk, loves.pos, loves.v2, 0.10, matWorld2);
    FEGYV_BM3_3:isHit:=-1 < _meglove(muks.gmbk, muks.kapcsk, loves.pos, loves.v2, 0.13, matWorld2);
    FEGYV_HPL:isHit:=-1 < _meglove(muks.gmbk, muks.kapcsk, loves.pos, loves.v2, 0.065, matWorld2);
    FEGYV_GUNSUPP:isHit:=-1 < _meglove(muks.gmbk, muks.kapcsk, loves.pos, loves.v2, 0.033, matWorld2);
    FEGYV_TECHSUPP:isHit:=-1 < _meglove(muks.gmbk, muks.kapcsk, loves.pos, loves.v2, 0.15, matWorld2);
  end;

  if isHit then
  begin
    state.isDead := ownProps.baseRespawnTime;
    putRagdoll(state.pos, loves.pos);
    if loves.kilotte <> -2 then
    begin
      _addHudMessage(lang[59] + lang[109] + lang[110], $FF0000);
      hudMessages[low(hudMessages)].fade:=200;
    end;
    exit;
  end;
end;

procedure TBot.doLogic;
const
  gravity = 0.3;
var
  mapHeight: Single;
  isOnSurface, isColliding, hasTarget: boolean;
  xSpeed, zSpeed: Single;
  //rotateYChange: Single;
  //tickNow: Cardinal;
begin
  //tickNow := getTickCount;
  if state.isDead > 0 then
  begin
    state.isDead := state.isDead - 1;
    exit;
  end
  else if state.isDead = 0 then
  begin
    state.pos := _getRandomPos(ownProps.respawnPos, ownProps.respawnRad);
    state.isDead := -1;
    state.isInvul := ownProps.baseInvulTime;
  end;
  if state.isInvul > 0 then
    state.isInvul := state.isInvul - 1
  else if state.isInvul = 0 then
    state.isInvul := -1;
  
  if state.checkTargets > 0 then
    state.checkTargets := state.checkTargets - 1;
  if state.canShootCd > 0 then
    state.canShootCd := state.canShootCd - 0.01;
	
  //hasTarget := FALSE;
  //isOnSurface := FALSE;
  resetMozgas;

  mapHeight := _advwove(state.pos.x, state.pos.z);

  //underwater
  if state.pos.y < (waterlevel-1.5) then
  begin
    state.isDead := ownProps.baseRespawnTime;
    putRagdoll(state.pos, state.pos);
    exit;
  end;

  //unclip terrain
  if (mapHeight > state.pos.y) then
  begin
    state.pos.y := mapHeight;
    resetMozgas;
  end;

  //add gravity to mozgas
  if (mapHeight < state.pos.y - gravity) then
    state.mozgas.y := -gravity;

  isOnSurface := (state.mozgas.y = 0) or hasOjjektumCollide; //collided because of gravity
  if not isOnSurface then applyMozgas;
  resetMozgas;

  if isOnSurface and (state.checkTargets <= 0) then
  begin
    state.checkTargets := ownProps.baseReactionTime;
    state.targetVec := findTarget;
  end;
  hasTarget := isOnSurface and not D3DXVector3Equal(state.targetVec, D3DXVector3(0, 0, 0));
  if hasTarget then facePoint(state.targetVec);

  case ownProps.botMode of
    BOT_DUMMY: state.mozgas := D3DXVector3(0, 0, 0);
    BOT_NORMAL:
    begin
        if hasTarget and (state.canShootCd <= 0) then
        begin
           shootPoint(state.targetVec);
        end
        else
        begin
          //case random(11) of
          //  0..2: rotateYChange := DegToRad(15);
          //  3..5: rotateYChange := -DegToRad(15);
          //  6..7: rotateYChange := DegToRad(45);
          //  8..9: rotateYChange := -DegToRad(45);
          //  10: rotateYChange := D3DX_PI;
          //end;
          //state.rotateY := state.rotateY + rotateYChange;

          xSpeed := (sin(state.rotateY) * ownProps.baseSpeed);
          zSpeed := (cos(state.rotateY) * ownProps.baseSpeed);

          state.mozgas := D3DXVector3(xSpeed, 0, zSpeed);
        end;

    end; //NORMAL mode end

  end; //botMode case end

  //don't move while targetting
  if hasTarget then resetMozgas;

  isColliding := hasOjjektumCollide; //collided while trying to move
  state.isMoving := (state.mozgas.x <> 0) or (state.mozgas.z <> 0);

  if not isColliding and isOnSurface and not hasTarget and state.isMoving then
    applyMozgas;

end;

procedure TBot.passInfo(
  _playerHalott: boolean;
  _playerFegyv: Byte;
  _playerPos: TD3DXVector3;
  _playerMatWorld: TD3DXMatrix;
  _bots: array of TBot
);
var
  botIndex: Integer;
  isGun, amGun, isAlly: boolean;
label
  skip;
begin
  foreignProps.playerPos := _playerPos;
  foreignProps.playerFegyv := _playerFegyv;
  foreignProps.playerHalott := _playerHalott;
  foreignProps.playerMatWorld := _playerMatWorld;
  
  amGun := ownProps.fegyv < 128;
  setlength(foreignProps.allies, 0);
  setlength(foreignProps.enemies, 0);
  for botIndex := low(_bots) to high(_bots) do
  begin 
    if _bots[botIndex].state.isDead > -1 then goto skip;
    if _bots[botIndex].state.isInvul > -1 then goto skip;
    if tavPointPoint(_bots[botIndex].state.pos, state.pos) > ownProps.baseVisibilityRadius
      then goto skip;
    isGun := _bots[botIndex].ownProps.fegyv < 128;
    isAlly := isGun = amGun;
    if isAlly then
    begin
      setlength(foreignProps.allies, succ(length(foreignProps.allies)));
      foreignProps.allies[high(foreignProps.allies)] := _bots[botIndex].state.pos;
    end
    else
    begin
      setlength(foreignProps.enemies, succ(length(foreignProps.enemies)));
      foreignProps.enemies[high(foreignProps.enemies)] := _bots[botIndex].state.pos;
    end;
    skip:
  end;
end;

function TBot.getFegyv(): BYTE;
begin
  result := ownProps.fegyv;
end;

function TBot.getIsDead(): boolean;
begin
  result := state.isDead <> -1;
end;

procedure TBot.putRagdoll(_pos: TD3DXVector3; forceRajtam: TD3DXVector3);
var
  matWorld, matWorld2:TD3DMatrix;
  tmp: TD3DXVector3;
begin
  D3DXMatrixRotationY(matWorld2, state.rotateY + D3DX_PI);
  D3DXMatrixTranslation(matWorld, _pos.x, _pos.y, _pos.z);
  D3DXMatrixMultiply(matWorld2, matWorld2, matWorld);
  d3dxvec3subtract(tmp, D3DXVector3(_pos.x, _pos.y + 1, _pos.z), forceRajtam);
  fastvec3normalize(tmp);
  constraintvec(tmp);
  _addrongybaba(_pos, state.mozgas, tmp, ownProps.fegyv, 0, 1, state.lastMuks, matWorld2);
end;


///////////////////////
//     TBOTGROUP     //
///////////////////////

constructor TBotGroup.Create(
      _id: Cardinal;
      _maxSize: Cardinal;
      _team: string;
      _botMode: TBotMode;
      _spawnpos: TD3DXVector3;
      _spawnrad: Cardinal
    );
begin
  id := _id;
  size := 0;
  maxSize := _maxSize;
  botMode := _botMode;
  team := _team;
  spawnpos := _spawnpos;
  spawnrad := _spawnrad; 
end;

function TBotGroup.Add(bot: TBot): Integer;
begin
  result := -1;
  if (size < maxSize) then
  begin
    setlength(bots, size + 1);
    bots[high(bots)] := bot;
    result := size;
    size := size + 1;
  end;
end;

function TBotGroup.AddFegyv(fegyv: Byte): Integer;
var
  n: Integer;
  BU: ByteArrayUtils;
label skip;
begin
  result := -1;
  BU := ByteArrayUtils.Create();

  n := BU.indexOf(fegyvs, fegyv);
  if (n <> -1) then goto skip;

  setlength(fegyvs, length(fegyvs) + 1);
  fegyvs[high(fegyvs)] := fegyv;
  result := high(fegyvs);

  skip:
end;

end.
