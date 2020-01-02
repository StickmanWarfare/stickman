unit m82a1;

interface
  uses AbstractFegyv, typestuff, Direct3d9, d3dx9;

type TF_M82A1 = class(TAbstractScopeFegyv)
  protected
    procedure makemuzzle; override;
    procedure makescalequad(hol:integer;m1, m2, m3, m4:TD3DXVector3); override;
  public
    procedure drawscope; override;
    procedure pluszmuzzmatr(siz:single); override;
    procedure drawmuzzle(siz:single); override;
  end;



implementation

procedure TF_M82A1.makescalequad(hol:integer;m1, m2, m3, m4:TD3DXVector3);
var
  v1, v2, v3, v4:TSkyVertex;
const
  uvszorzo = 5;
begin
  v1.position:=m1;v2.position:=m2;v3.position:=m3;v4.position:=m4;
  v1.u:=v1.position.x * uvszorzo;v1.v:=v1.position.y * uvszorzo;
  v2.u:=v2.position.x * uvszorzo;v2.v:=v2.position.y * uvszorzo;
  v3.u:=v3.position.x * uvszorzo;v3.v:=v3.position.y * uvszorzo;
  v4.u:=v4.position.x * uvszorzo;v4.v:=v4.position.y * uvszorzo;
  //v5.u:=v5.position.x*uvszorzo; v5.v:=v5.position.y*uvszorzo;
  scal[hol + 0]:=v1;
  scal[hol + 1]:=v2;
  scal[hol + 2]:=v3;
  scal[hol + 3]:=v3;
  scal[hol + 4]:=v2;
  scal[hol + 5]:=v4;
end;

procedure TF_M82A1.makemuzzle;
begin
  makemuzzlequad(0, CustomVertex(-0.5, -0.5, 0, 0, 0, 0, ARGB(255, 255, 255, 255), 0, 0, 0, 0),
    CustomVertex(0.5, -0.5, 0, 0, 0, 0, ARGB(255, 255, 255, 255), 2, 0, 0, 0),
    CustomVertex(-0.5, 0.5, 0, 0, 0, 0, ARGB(255, 255, 255, 255), 0, 2, 0, 0),
    CustomVertex(0.5, 0.5, 0, 0, 0, 0, ARGB(255, 255, 255, 255), 2, 2, 0, 0));
  makemuzzlequad(6, CustomVertex(0, 0, 0, 0, 0, 0, ARGB(255, 255, 255, 255), 0, 0, 0, 0),
    CustomVertex(0, 0.5, -0.5, 0, 0, 0, ARGB(255, 255, 255, 255), 1, 0, 0, 0),
    CustomVertex(0, -0.5, -0.5, 0, 0, 0, ARGB(255, 255, 255, 255), 0, 1, 0, 0),
    CustomVertex(0, 0, -1, 0, 0, 0, ARGB(255, 255, 255, 255), 1, 1, 0, 0));
  makemuzzlequad(12, CustomVertex(0, 0, 0, 0, 0, 0, ARGB(255, 255, 255, 255), 0, 0, 0, 0),
    CustomVertex(0.5, 0, -0.5, 0, 0, 0, ARGB(255, 255, 255, 255), 1, 0, 0, 0),
    CustomVertex(-0.5, 0, -0.5, 0, 0, 0, ARGB(255, 255, 255, 255), 0, 1, 0, 0),
    CustomVertex(0, 0, -1, 0, 0, 0, ARGB(255, 255, 255, 255), 1, 1, 0, 0));

  makescalequad(0, D3DXVector3(-0.02, 0.00003, -0.2), D3DXVector3(-0.02, -0.000025, -0.2),
    D3DXVector3(0.02, 0.00003, -0.2), D3DXVector3(0.02, -0.000025, -0.2));
  makescalequad(6, D3DXVector3(-0.00003, 0.02, -0.2), D3DXVector3(-0.000025, -0.02, -0.2),
    D3DXVector3(0.00003, 0.02, -0.2), D3DXVector3(0.000025, -0.02, -0.2));
end;

procedure TF_M82A1.drawscope;
begin
  g_pd3dDevice.SetFVF(D3DFVF_SKYVERTEX);
  g_pd3ddevice.settexture(0, scaltex);
  g_pd3ddevice.drawprimitiveUP(D3DPT_TRIANGLELIST, 4, scal, sizeof(Tskyvertex));
end;

procedure TF_M82A1.pluszmuzzmatr(siz:single);
var
  matWorld, matWorld2:TD3DMatrix;
begin

  D3DXMatrixTranslation(matWorld, -0.00, -0.05, -1.3);
  D3DXMatrixScaling(matWorld2, siz / 2, siz / 2, siz);
  D3DXmatrixMultiply(matWorld, matWorld2, MatWorld);
  g_pd3dDevice.MultiplyTransform(D3DTS_WORLD, matWorld);

end;

procedure TF_M82A1.drawmuzzle(siz:single);
var
  mat:TD3DMatrix;
  lngt, i:integer;
begin
  if siz = 0 then exit;

  pluszmuzzmatr(siz);

  g_pd3ddevice.GetTransform(D3DTS_WORLD, mat);
  lngt:=length(muzzez);
  setlength(muzzez, lngt + length(muzz));
  for i:=0 to high(muzz) do
  begin
    muzzez[i + lngt]:=muzz[i];
    D3DXVec3TransformCoord(muzzez[i + lngt].position, muzz[i].position, mat);
  end;
  // g_pd3ddevice.drawprimitiveUP(D3DPT_TRIANGLELIST,6,muzz,sizeof(TCustomvertex));
end;

end.
 