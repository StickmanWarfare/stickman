unit bm3;

interface   
  uses AbstractFegyv, typestuff, Direct3d9, d3dx9;

type TF_BM3 = class(TAbstractFegyv)
  protected
    procedure makemuzzle; override;
  public
    procedure pluszmuzzmatr(siz:single); override;
    procedure drawmuzzle(siz:single); override;
  end;



implementation

 ////////////////////////////////
//            BM3
///////////////////////////////
procedure TF_BM3.makemuzzle;
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

end;

procedure TF_BM3.pluszmuzzmatr(siz:single);
var
  matWorld, matWorld2:TD3DMatrix;
begin

  D3DXMatrixTranslation(matWorld, -0.00, -0.015, -0.89);
  D3DXMatrixScaling(matWorld2, siz / 2, siz / 2, siz);
  D3DXmatrixMultiply(matWorld, matWorld2, MatWorld);
  g_pd3dDevice.MultiplyTransform(D3DTS_WORLD, matWorld);

end;

procedure TF_BM3.drawmuzzle(siz:single);
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
 