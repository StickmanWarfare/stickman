unit x72;

interface   
  uses AbstractFegyv, typestuff, Direct3d9, d3dx9, Math, windows;

type TF_X72 = class(TAbsctractEmittingFegyv)
  protected
    procedure makemuzzle; override;
    procedure setupMesh; override;
  public
    procedure pluszmuzzmatr(siz:single); override;
    procedure drawmuzzle(siz:single); override;
  end;

implementation

procedure TF_X72.setupMesh;
var
  pVert:PCustomvertexarray;
  vmi, vma, tmp:TD3DVector;
  scl:single;
  i:integer;
begin
  g_pMesh.LockVertexBuffer(0, pointer(pvert));
  D3DXComputeboundingbox(pointer(pvert), g_pMesh.GetNumVertices, g_pMesh.GetNumBytesPerVertex, vmi, vma);
  scl:=max(vma.x - vmi.x, max(vma.y - vmi.y, vma.z - vmi.z));
  scl:=scl / 0.7;
  fc:=(vma.z - vmi.z) * 0.5;
  for i:=0 to g_pMesh.GetNumVertices - 1 do
  begin
    tmp.x:=(pvert[i].position.x) / scl;
    tmp.y:=(pvert[i].position.y - vma.y) / scl;
    tmp.z:=(pvert[i].position.z - vma.z) / scl; //+0.001;
    if abs(tmp.x) < 0.005 then tmp.x:=0;
    pvert[i].color:=RGB(200, 200, 200);
    pvert[i].position:=tmp;
  end;
  g_pMesh.UnlockVertexBuffer;
end;


procedure TF_X72.makemuzzle;
begin
  makemuzzlequad(0, CustomVertex(-0.5, -0.5, 0, 0, 0, 0, weapons[4].col[8], 0, 0, 0, 0),
    CustomVertex(0.5, -0.5, 0, 0, 0, 0, weapons[4].col[8], 0, 2, 0, 0),
    CustomVertex(-0.5, 0.5, 0, 0, 0, 0, weapons[4].col[8], 1, 0, 0, 0),
    CustomVertex(0.5, 0.5, 0, 0, 0, 0, weapons[4].col[8], 1, 2, 0, 0));
  makemuzzlequad(6, CustomVertex(0, 0.5, 0, 0, 0, 0, weapons[4].col[8], 0, 1, 0, 0),
    CustomVertex(0, -0.5, 0, 0, 0, 0, weapons[4].col[8], 1, 1, 0, 0),
    CustomVertex(0, 0.5, -1, 0, 0, 0, weapons[4].col[8], 0, 0, 0, 0),
    CustomVertex(0, -0.5, -1, 0, 0, 0, weapons[4].col[8], 1, 0, 0, 0));
  makemuzzlequad(12, CustomVertex(0.5, 0, 0, 0, 0, 0, weapons[4].col[8], 0, 1, 0, 0),
    CustomVertex(-0.5, 0, 0, 0, 0, 0, weapons[4].col[8], 1, 1, 0, 0),
    CustomVertex(0.5, 0, -1, 0, 0, 0, weapons[4].col[8], 0, 0, 0, 0),
    CustomVertex(-0.5, 0, -1, 0, 0, 0, weapons[4].col[8], 1, 0, 0, 0));
end;


procedure TF_X72.pluszmuzzmatr(siz:single);
var
  matWorld, matWorld2:TD3DMatrix;
begin

  D3DXMatrixTranslation(matWorld, -0.00, -0.08, -0.7);
  D3DXMatrixScaling(matWorld2, (1 - siz), siz, siz * 2);
  D3DXmatrixMultiply(matWorld, matWorld2, MatWorld);
  g_pd3dDevice.MultiplyTransform(D3DTS_WORLD, matWorld);

end;

procedure TF_X72.drawmuzzle(siz:single);
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
  //   g_pd3ddevice.drawprimitiveUP(D3DPT_TRIANGLELIST,6,muzz,sizeof(TCustomvertex));
end;


end.
