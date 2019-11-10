unit Selfie;

interface

uses
  Math,
  D3DX9, 
  Direct3D9,
  Typestuff,
  muksoka;

type TSelfie = class
public
  isSelfieModeOn: boolean;
  zoomlevel: (CLOSE, NORMAL, WIDE);
  dab: boolean;
  muks: TMuksoka;
  fejcuccrenderer: TFejcuccrenderer;
  fegyv: BYTE;
  fejcucc: Integer;
  campos: TD3DXVector3;
  camrotX: single;
  camrotY: single;
  constructor Create(
    _muks: TMuksoka;
    _fegyv: BYTE;
    _fejcucc: Integer;
    _campos: TD3DXVector3;
    _camrotX: single;
    _camrotY: single
  );
  procedure render;
  procedure toggle;
end;

implementation


constructor TSelfie.Create(
  _muks: TMuksoka;
  _fegyv: BYTE;
  _fejcucc: Integer;
  _campos: TD3DXVector3;
  _camrotX: single;
  _camrotY: single
);
begin
  isSelfieModeOn := FALSE;
  dab := FALSE;
  zoomlevel := CLOSE;
  muks := _muks;
  fegyv := _fegyv;
  fejcucc := _fejcucc;
  campos := _campos;
  camrotX := _camrotX;
  camrotY := _camrotY;
end;

procedure TSelfie.render;
var
  szin: Cardinal;
  matWorld, matWorld2, matb: TD3DMatrix;
  pos: TD3DXVector3;
  cameraDistance: 1..5;
begin
  if not isSelfieModeOn then exit;

  cameraDistance := 2;
  case zoomlevel of
    CLOSE: cameraDistance := 1;
    NORMAL: cameraDistance := 2;
    WIDE: cameraDistance := 5;
  end;

  if fegyv < 128 then szin := gunszin else szin := techszin;
  D3DXVec3Add(
    pos,
    campos,
    D3DXVector3(
      sin(camrotX) * cameraDistance,
      0,
      cos(camrotX) * cameraDistance
    )
  );
  D3DXMatrixRotationY(matWorld2, camrotX); //+PI -PI lel
  D3DXMatrixRotationX(matb, clipszogybajusz(camrotY));
  D3DXMatrixMultiply(matb, matb, matWorld2);
  D3DXMatrixTranslation(matWorld, pos.x, pos.y, pos.z);
  D3DXMatrixMultiply(matWorld2, matWorld2, matWorld);
  D3DXMatrixTranslation(matWorld, pos.x, pos.y, pos.z);
  D3DXMatrixMultiply(matb, matb, matWorld);

  if dab then
  begin
    //jobb konyok fejbe aztan ki
    muks.gmbk[6] := muks.gmbk[10];
    muks.gmbk[6].x := muks.gmbk[6].x - 0.2;

    //jobb kezfej fejbe aztan ki es fel
    muks.gmbk[8] := muks.gmbk[10];
    muks.gmbk[8].x := muks.gmbk[8].x - 0.4;
    muks.gmbk[8].y := muks.gmbk[8].y + 0.2;

    //bal konyok fejbe aztan elore es masik ki es le
    muks.gmbk[7] := muks.gmbk[10];
    muks.gmbk[7].x := muks.gmbk[7].x + 0.12;
    muks.gmbk[7].y := muks.gmbk[7].y - 0.1;
    muks.gmbk[7].z := muks.gmbk[7].z - 0.4;

    //bal kezfej fejbe aztan elore es ki es fel
    muks.gmbk[9] := muks.gmbk[10];
    muks.gmbk[9].x := muks.gmbk[9].x - 0.08;
    muks.gmbk[9].y := muks.gmbk[9].y + 0.08;
    muks.gmbk[9].z := muks.gmbk[9].z - 0.4;
  end
  else
  begin
    if zoomlevel = CLOSE then //fogom a kamerat
    begin
      //arcomba rakom a kezem
      muks.gmbk[8] := campos;
      muks.gmbk[8].y := muks.gmbk[8].y + 0.2;

      //jobb konyok kicsit kamera fele
      muks.gmbk[6].x := muks.gmbk[6].x - 0.2;
      muks.gmbk[6].y := muks.gmbk[6].y + 0.1;
      muks.gmbk[6].z := muks.gmbk[6].z - 0.2;
    end
    else
    begin
      //jobb kezfej testem melle es le
      muks.gmbk[8].x := muks.gmbk[8].x - 0.1;
      muks.gmbk[8].y := muks.gmbk[8].y - 0.1;
      muks.gmbk[8].z := muks.gmbk[8].z + 0.2;
      
      //jobb konyok testem melle
      muks.gmbk[6].x := muks.gmbk[6].x - 0.1;
      muks.gmbk[6].z := muks.gmbk[6].z + 0.2;
    end;

    //bal konyok testem melle es fel
    muks.gmbk[7].x := muks.gmbk[7].x + 0.2;
    muks.gmbk[7].y := muks.gmbk[7].y + 0.2;
    muks.gmbk[7].z := muks.gmbk[7].z + 0.2;

    //bal kezfej testem melle es fel
    muks.gmbk[9].x := muks.gmbk[9].x + 0.3;
    muks.gmbk[9].y := muks.gmbk[9].y + 0.4;
    muks.gmbk[9].z := muks.gmbk[9].z + 0.2;
  end;


  muks.Render(szin, matWorld2, campos);

  //fejcucc modifier
  matb._41 := matb._41 + muks.gmbk[10].x;
  matb._42 := matb._42 + muks.gmbk[10].y;
  matb._43 := matb._43 + muks.gmbk[10].z;
  fejcuccrenderer.render(fejcucc, matb, false, pos);
end;


procedure TSelfie.toggle;
begin
  isSelfieModeOn := not isSelfieModeOn;
end;

end.
