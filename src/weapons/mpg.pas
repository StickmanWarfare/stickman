unit mpg;

interface
  uses AbstractFegyv, typestuff, Direct3d9, d3dx9, Math, windows;

type TF_MPG = class(TAbsctractEmittingSmallMuzzFegyv)
  protected
    procedure makemuzzle(alpha:single); reintroduce; override;
    procedure setupMesh; override;
  public
    procedure pluszmuzzmatr(siz:single;szog:single); reintroduce; override;
    procedure drawmuzzle(siz:single;szog:single); reintroduce; override;
  end;

implementation

procedure TF_MPG.setupMesh;
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
  fc:=(vma.z - vmi.z) * 0.5 / scl;
  for i:=0 to g_pMesh.GetNumVertices - 1 do
  begin
    tmp.z:= -(pvert[i].position.x - vmi.x) * 0.9 / scl;
    tmp.y:=(pvert[i].position.y - vma.y) / scl;
    tmp.x:=(pvert[i].position.z - vma.z) / scl + fc;
    pvert[i].color:=ARGB(0, 200, 200, 200);
    pvert[i].position:=tmp;
    pvert[i].u2:=pvert[i].u;
    pvert[i].v2:=pvert[i].v;
  end;
  g_pMesh.UnlockVertexBuffer;
end;

procedure TF_MPG.makemuzzle(alpha:single);
var
  c:TD3DXColor;
  col:cardinal;
begin
  c:=D3DXColorFromDWord(weapons[1].col[4]);
  c.a:=c.a * alpha;
  col:=D3DXColorToDWord(c);
  muzz[0]:=CustomVertex(-0.5, -0.5, 0, 0, 0, 0, col, 0, 0, 0, 0);
  muzz[1]:=CustomVertex(0.5, -0.5, 0, 0, 0, 0, col, 1, 0, 0, 0);
  muzz[2]:=CustomVertex(-0.5, 0.5, 0, 0, 0, 0, col, 0, 1, 0, 0);
  muzz[3]:=CustomVertex(0.5, 0.5, 0, 0, 0, 0, col, 1, 1, 0, 0);
  muzz[4]:=CustomVertex(0.5, -0.5, 0, 0, 0, 0, col, 1, 0, 0, 0);
  muzz[5]:=CustomVertex(-0.5, 0.5, 0, 0, 0, 0, col, 0, 1, 0, 0);
end;

procedure TF_MPG.pluszmuzzmatr(siz:single;szog:single);
var
  matWorld, matWorld2:TD3DMatrix;
begin
  D3DXMatrixTranslation(matWorld, -0.00, -0.08, -0.7);
  D3DXMatrixRotationZ(matWorld2, szog);
  D3DXmatrixMultiply(matWorld, matWorld2, MatWorld);
  D3DXMatrixScaling(matWorld2, siz, siz, siz);
  D3DXmatrixMultiply(matWorld, matWorld2, MatWorld);
  g_pd3dDevice.MultiplyTransform(D3DTS_WORLD, matWorld);
end;

procedure TF_MPG.drawmuzzle(siz:single;szog:single);
var
  mat:TD3DMatrix;
  lngt, i:integer;
begin
  if siz >= 1 then exit;

  makemuzzle(1 - siz);
  pluszmuzzmatr(siz / 2, szog);

  g_pd3ddevice.GetTransform(D3DTS_WORLD, mat);
  lngt:=length(muzzez);
  setlength(muzzez, lngt + length(muzz));
  for i:=0 to high(muzz) do
  begin
    muzzez[i + lngt]:=muzz[i];
    D3DXVec3TransformCoord(muzzez[i + lngt].position, muzz[i].position, mat);
  end;
end;

end.
