unit fegyverek;

interface
uses
  windows, typestuff, math, Direct3d9, d3dx9, AbstractFegyv, FegyvBuilder,
  m4a1, m82a1, law, mp5a3, bm3,
  mpg, quadro, noob, x72, hpl,
  h31;
//const

//M4_Golyoido=0.3;
type
  Tprojectile = record
    p1, p2:TD3DXvector3;
    ido, mido:single;
  end;

  Tprojectilearray = array of Tprojectile;

  TFegyv = class(TObject)
  private
    g_pD3Ddevice:IDirect3ddevice9;
    M4proj, mpgproj:Tprojectilearray;
           
    B_M4A1, G_M4A1, M4A1:TF_M4A1;
    B_M82A1, G_M82A1, M82A1:TF_M82A1;
    B_MPG,  G_MPG, MPG:TF_MPG;
    B_LAW,  G_LAW, LAW:TF_LAW;
    B_NOOB, G_NOOB, NOOB:TF_NOOB;
    B_QUADRO, G_QUADRO, QUADRO:TF_QUADRO;
    B_MP5A3, G_MP5A3, MP5A3:TF_MP5A3;
    B_X72,  G_X72, X72:TF_X72;
    B_BM3,  G_BM3, BM3:TF_BM3;
    B_HPL,  G_HPL, HPL:TF_HPL;
    //GUNSUPP: TF_GUNSUPP;
    //TECHSUPP: TF_TECHSUPP;

    H31:TF_H31;

    gunmuztex, mpgmuztex, x72muztex:IDirect3DTexture9;
    g_pVB:IDirect3DVertexBuffer9;
  public
    betoltve:boolean;
    constructor Create(a_D3Ddevice:IDirect3ddevice9);
    procedure drawfegyv(mit:byte;felhocoverage:byte;fegylit:byte);
    procedure drawscope(mit:byte);
    procedure preparealpha;
    procedure drawfegyeffekt(mit:byte;mekkora:single;szog:single);
    procedure FlushFegyeffekt;
    procedure unpreparealpha;
    function bkez(afegyv:word;astate:byte;szogy:single = 0):TD3DXVector3;
    function jkez(afegyv:word;astate:byte;szogy:single = 0):TD3DXVector3;
    destructor Destroy; reintroduce;
  end;
     
implementation

constructor TFegyv.Create(a_D3Ddevice:IDirect3ddevice9);
var
  factory: TFegyvFactory;
begin
  inherited Create;
  betoltve:=false;
  g_pD3Ddevice:=a_D3Ddevice;
  factory := TFegyvFactory.Create(g_pD3Ddevice);
  if winter then
    factory.setSkin(SKIN_NAME_XMAS);

  factory.make;
  
  M4A1 := factory.M4A1;
  M82A1 := factory.M82A1;
  MP5A3 := factory.MP5A3;
  LAW := factory.LAW;
  BM3 := factory.BM3;

  MPG := factory.MPG;
  QUADRO := factory.QUADRO;
  NOOB := factory.NOOB;
  X72 := factory.X72;
  HPL := factory.HPL;

  if winter then
    H31 := factory.H31;

   {
  //SKINEK
  G_M4A1:=TF_M4A1.create(a_D3Ddevice, 'm4a1', 'golden');
  if not G_M4A1.betoltve then exit;
  G_M82A1:=TF_M82A1.create(a_D3Ddevice, 'm82', 'golden');
  if not G_M82A1.betoltve then exit;
  G_LAW:=TF_LAW.create(a_D3Ddevice, 'law', 'golden');
  if not G_LAW.betoltve then exit;
  G_MP5A3:=TF_MP5A3.create(a_D3Ddevice, 'mp5', 'golden');
  if not G_MP5A3.betoltve then exit;
  G_BM3:=TF_BM3.create(a_D3Ddevice, 'bm3', 'golden');
  if not G_BM3.betoltve then exit;
  G_NOOB:=TF_NOOB.create(a_D3Ddevice, 'noob', 'golden');
  if not G_NOOB.betoltve then exit;
  G_X72:=TF_X72.create(a_D3Ddevice, 'x72', 'golden');
  if not G_x72.betoltve then exit;
  G_MPG:=TF_MPG.create(a_D3Ddevice, 'mpg', 'golden');
  if not G_MPG.betoltve then exit;
  G_QUADRO:=TF_QUADRO.create(a_D3Ddevice, 'quad', 'golden');
  if not G_QUADRO.betoltve then exit;
  G_HPL:=TF_HPL.create(a_D3Ddevice, 'hpl', 'golden');
  if not G_HPL.betoltve then exit;


  B_M4A1:=TF_M4A1.create(a_D3Ddevice, 'm4a1', 'blue');
  if not B_M4A1.betoltve then exit;
  B_M82A1:=TF_M82A1.create(a_D3Ddevice, 'm82', 'blue');
  if not B_M82A1.betoltve then exit;
  B_LAW:=TF_LAW.create(a_D3Ddevice, 'law', 'blue');
  if not B_LAW.betoltve then exit;
  B_MP5A3:=TF_MP5A3.create(a_D3Ddevice, 'mp5', 'blue');
  if not B_MP5A3.betoltve then exit;
  B_BM3:=TF_BM3.create(a_D3Ddevice, 'bm3', 'blue');
  if not B_BM3.betoltve then exit;
  B_NOOB:=TF_NOOB.create(a_D3Ddevice, 'noob', 'blue');
  if not B_NOOB.betoltve then exit;
  B_X72:=TF_X72.create(a_D3Ddevice, 'x72', 'blue');
  if not B_x72.betoltve then exit;
  B_MPG:=TF_MPG.create(a_D3Ddevice, 'mpg', 'blue');
  if not B_MPG.betoltve then exit;
  B_QUADRO:=TF_QUADRO.create(a_D3Ddevice, 'quad', 'blue');
  if not B_QUADRO.betoltve then exit;
  B_HPL:=TF_HPL.create(a_D3Ddevice, 'hpl', 'blue');
  if not B_HPL.betoltve then exit;
  //SKINEK END
       }

  if not LTFF(g_pd3dDevice, 'data/textures/weapons/muzzle/m4a1muzz.png', gunmuztex) then
    Exit;

  if not LTFF(g_pd3dDevice, 'data/textures/weapons/muzzle/mpgmuzz.png', mpgmuztex) then
    Exit;

  if not LTFF(g_pd3dDevice, 'data/textures/weapons/muzzle/x72muzz.png', x72muztex) then
    Exit;

  if FAILED(g_pd3dDevice.CreateVertexBuffer(5000 * sizeof(TCustomVertex),
    D3DUSAGE_WRITEONLY or D3DUSAGE_DYNAMIC, D3DFVF_CUSTOMVERTEX,
    D3DPOOL_DEFAULT, g_pVB, nil))
    then Exit;

  betoltve:=true;
end;

procedure TFegyv.drawfegyv(mit:byte;felhocoverage:byte;fegylit:byte);
var
  matViewproj, invWorld:TD3DXMatrix;
  tex:^IDirect3DTexture9;
  tmplw:longword;
  em:^IDirect3DTexture9;
  vanem:boolean;
//  i:integer;
begin

  g_pd3dDevice.SetRenderState(D3DRS_CULLMODE, D3DCULL_CCW);
  //  g_pd3dDevice.SetRenderState(D3DRS_AMBIENT,$FFFFFFFF);
  //  g_pd3ddevice.SetRenderState(D3DRS_BLENDFACTOR,$FFFFFFFF);
  //  g_pd3dDevice.SetRenderState(D3DRS_ALPHABLENDENABLE,ifalse);
  g_pd3dDevice.SetRenderState(D3DRS_ZWriteENABLE, iTrue);
  g_pd3dDevice.SetRenderState(D3DRS_LIGHTING, itrue);

  g_pd3dDevice.SetRenderState(D3DRS_SRCBLEND, D3DBLEND_SRCALPHA);
  //  g_pd3dDevice.SetRenderState(D3DRS_DESTBLEND,D3DBLEND_SRCALPHA);
  g_pd3dDevice.SetRenderState(D3DRS_DESTBLEND, D3DBLEND_ONE);
  g_pd3ddevice.SetRenderState(D3DRS_BLENDOP, D3DBLENDOP_ADD);

  g_pd3dDevice.SetTextureStageState(0, D3DTSS_COLOROP, FAKE_HDR);
  //  g_pd3dDevice.SetTextureStageState(0,D3DTSS_COLOROP,D3DTOP_SELECTARG1);
  g_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_MODULATE);

  g_pd3dDevice.SetTextureStageState(0, D3DTSS_COLORARG1, D3DTA_DIFFUSE);
  g_pd3dDevice.SetTextureStageState(0, D3DTSS_COLORARG2, D3DTA_TEXTURE);
  g_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAARG1, D3DTA_DIFFUSE);
  g_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAARG2, D3DTA_TEXTURE);

  g_pd3dDevice.SetSamplerState(0, D3DSAMP_ADDRESSU, D3DTADDRESS_MIRROR);
  g_pd3dDevice.SetSamplerState(0, D3DSAMP_ADDRESSV, D3DTADDRESS_MIRROR);
  g_pd3dDevice.SetSamplerState(0, D3DSAMP_MIPFILTER, D3DTEXF_POINT);

  vanem:=false;
  em:=nil;
  tex:=nil;

  if (G_peffect <> nil) then
  begin

    case mit of
		  FEGYV_M4A1:tex:=@M4A1.skin;
		  FEGYV_M82A1:tex:=@M82A1.skin;
		  FEGYV_LAW:tex:=@LAW.skin;
		  FEGYV_MPG:tex:=@MPG.skin;
		  FEGYV_QUAD:tex:=@QUADRO.skin;
		  FEGYV_NOOB:tex:=@NOOB.skin;
		  FEGYV_MP5A3:tex:=@MP5A3.skin;
		  FEGYV_X72:tex:=@X72.skin;
		  FEGYV_BM3:tex:=@BM3.skin;
		  FEGYV_HPL:tex:=@HPL.skin;
      //FEGYV_GUNSUPP:tex:=@GUNSUPP.tex;
      //FEGYV_TECHSUPP:tex:=@TECHSUPP.tex;
          
		  FEGYV_H31_G:tex:=@H31.skin;
		  FEGYV_H31_T:tex:=@H31.skin;
            {
		  FEGYV_G_M4A1:tex:=@G_M4A1.skin;
		  FEGYV_G_M82A1:tex:=@G_M82A1.skin;
		  FEGYV_G_LAW:tex:=@g_LAW.skin;
		  FEGYV_G_MPG:tex:=@G_MPG.mpgtex;
		  FEGYV_G_QUAD:tex:=@G_QUADRO.quadrotex;
		  FEGYV_G_NOOB:tex:=@G_NOOB.tex;
		  FEGYV_G_MP5A3:tex:=@G_MP5A3.skin;
		  FEGYV_G_X72:tex:=@G_X72.x72tex;
		  FEGYV_G_BM3:tex:=@G_BM3.skin;
		  FEGYV_G_HPL:tex:=@G_HPL.m4tex;
          
		  FEGYV_B_M4A1:tex:=@B_M4A1.skin;
		  FEGYV_B_M82A1:tex:=@B_M82A1.skin;
		  FEGYV_B_LAW:tex:=@B_LAW.skin;
		  FEGYV_B_MPG:tex:=@B_MPG.mpgtex;
		  FEGYV_B_QUAD:tex:=@B_QUADRO.quadrotex;
		  FEGYV_B_NOOB:tex:=@B_NOOB.tex;
		  FEGYV_B_MP5A3:tex:=@B_MP5A3.skin;
		  FEGYV_B_X72:tex:=@B_X72.x72tex;
		  FEGYV_B_BM3:tex:=@B_BM3.skin;
		  FEGYV_B_HPL:tex:=@B_HPL.m4tex;    }
    end;



    case mit of
	    FEGYV_MPG:em:=@MPG.emap;
      FEGYV_QUAD:em:=@QUADRO.emap;
      FEGYV_NOOB:em:=@NOOB.emap;
      FEGYV_X72:em:=@X72.emap;
      FEGYV_HPL:em:=@HPL.emap;
      //FEGYV_TECHSUPP:em:=@TECHSUPP.emap;

      FEGYV_G_MPG:em:=@G_MPG.emap;
      FEGYV_G_QUAD:em:=@G_QUADRO.emap;
      FEGYV_G_NOOB:em:=@G_NOOB.emap;
      FEGYV_G_X72:em:=@G_X72.emap;
      FEGYV_G_HPL:em:=@G_HPL.emap;
	  
	    FEGYV_B_MPG:em:=@B_MPG.emap;
      FEGYV_B_QUAD:em:=@B_QUADRO.emap;
      FEGYV_B_NOOB:em:=@B_NOOB.emap;
      FEGYV_B_X72:em:=@B_X72.emap;
      FEGYV_B_HPL:em:=@B_HPL.emap;
    end;

    if em <> nil then vanem:=true;

    g_pd3ddevice.SetFVF(D3DFVF_SKYVERTEX);

  end;

  if (G_peffect <> nil) and (opt_detail >= DETAIL_POM) then
  begin

    g_peffect.SetTechnique('Wn');

    g_pd3ddevice.GetTransform(D3DTS_WORLD, matViewproj);
    g_pEffect.SetMatrix('World', matViewproj);

    d3dxmatrixinverse(invWorld, nil, matViewproj);
    g_pEffect.SetMatrix('invWorld', invWorld);

    g_pd3dDevice.GetTransform(D3DTS_VIEW, matViewproj);
    g_pEffect.SetMatrix('View', matViewproj);

    g_pd3dDevice.GetTransform(D3DTS_PROJECTION, matViewproj);
    g_pEffect.SetMatrix('Projection', matViewproj);

    //     g_pd3ddevice.GetTransform(D3DTS_WORLD,matViewproj);  //D3DTS_VIEW //D3DTS_PROJECTION
    //     g_pd3ddevice.GetTransform(D3DTS_VIEW,matViewproj);
//

//
//    g_pd3ddevice.GetTransform(D3DTS_WORLD,matViewproj);
//    d3dxmatrixmultiply(matViewproj,matView,matViewproj);
//    g_pEffect.SetMatrix('g_mWorldView2',matViewproj);


//  g_pd3dDevice.GetTransform(D3DTS_WORLD, matWorld);

//  g_pd3ddevice.SetTransform(D3DTS_PROJECTION,matproj);

//        d3dxmatrixmultiply(matViewproj,matWorld,matProj);
//        d3dxmatrixmultiply(matViewproj,matView,matViewproj);
//        g_pEffect.SetMatrix('g_mWorldViewProjection',matViewproj);
//        g_pEffect.SetMatrix('g_mProj',matViewproj);

    g_peffect.SetFloat('fegylit', fegylit / 10);
    g_peffect.SetFloat('FogStart', fogstart);
    g_peffect.SetFloat('FogEnd', fogend);
    g_pEffect.SetTexture('g_MeshTexture', tex^);
    if vanem then
      g_pEffect.SetTexture('g_Emap', em^);
    g_pEffect.SetBool('vanemap', vanem);
    g_peffect.SetFloat('HDRszorzo', shaderhdr);
    g_peffect.SetFloat('sunpow', lerp(felhoszin2, felhoszin1, cloudblend));
    g_peffect.SetVector('g_CameraPosition', D3DXVector4(campos.x, campos.y, campos.z, 0));
    //    g_pd3ddevice.SetVertexdeclaration(vertdecl);
    g_peffect._Begin(@tmplw, 0);
    g_peffect.BeginPass(0);

  end
  else
    if (G_peffect <> nil) then //jobb shaderrel, mint simán, az emap így látszik mindenhol, a hdr meg el van intézve
    begin
      g_peffect.SetTechnique('WnHDR');

      g_pd3ddevice.GetTransform(D3DTS_WORLD, matViewproj);
      g_pEffect.SetMatrix('World', matViewproj);

      d3dxmatrixinverse(invWorld, nil, matViewproj);
      g_pEffect.SetMatrix('invWorld', invWorld);

      g_pd3dDevice.GetTransform(D3DTS_VIEW, matViewproj);
      g_pEffect.SetMatrix('View', matViewproj);

      g_pd3dDevice.GetTransform(D3DTS_PROJECTION, matViewproj);
      g_pEffect.SetMatrix('Projection', matViewproj);

      g_peffect.SetFloat('fegylit', fegylit / 10);
      g_peffect.SetFloat('FogStart', fogstart);
      g_peffect.SetFloat('FogEnd', fogend);
      g_pEffect.SetTexture('g_MeshTexture', tex^);
      if vanem then
        g_pEffect.SetTexture('g_Emap', em^);
      g_pEffect.SetBool('vanemap', vanem);
      //    g_peffect.SetFloat('HDRszorzo',shaderhdr);
      g_peffect.SetFloat('HDRszorzo', shaderhdr);


      g_peffect._Begin(@tmplw, 0);
      g_peffect.BeginPass(0);
    end;

  case mit of
		FEGYV_M4A1:M4A1.draw;
		FEGYV_M82A1:M82A1.draw;
		FEGYV_LAW:LAW.draw;
		FEGYV_MPG:MPG.draw;
		FEGYV_QUAD:QUADRO.draw;
		FEGYV_NOOB:NOOB.draw;
		FEGYV_MP5A3:MP5A3.draw;
		FEGYV_X72:X72.draw;
		FEGYV_BM3:BM3.draw;
		FEGYV_HPL:HPL.draw;
    //FEGYV_GUNSUPP:GUNSUPP.draw;
    //FEGYV_TECHSUPP:TECHSUPP.draw;

		FEGYV_H31_G:H31.draw;
		FEGYV_H31_T:H31.draw;

		FEGYV_G_M4A1:G_M4A1.draw;
		FEGYV_G_M82A1:G_M82A1.draw;
		FEGYV_G_LAW:G_LAW.draw;
		FEGYV_G_MPG:G_MPG.draw;
		FEGYV_G_QUAD:G_QUADRO.draw;
		FEGYV_G_NOOB:G_NOOB.draw;
		FEGYV_G_MP5A3:G_MP5A3.draw;
		FEGYV_G_X72:G_X72.draw;
		FEGYV_G_BM3:G_BM3.draw;
		FEGYV_G_HPL:G_HPL.draw;

		FEGYV_B_M4A1:B_M4A1.draw;
		FEGYV_B_M82A1:B_M82A1.draw;
		FEGYV_B_LAW:B_LAW.draw;
		FEGYV_B_MPG:B_MPG.draw;
		FEGYV_B_QUAD:B_QUADRO.draw;
		FEGYV_B_NOOB:B_NOOB.draw;
		FEGYV_B_MP5A3:B_MP5A3.draw;
		FEGYV_B_X72:B_X72.draw;
		FEGYV_B_BM3:B_BM3.draw;
		FEGYV_B_HPL:B_HPL.draw;
  end;

  if (G_peffect <> nil) then
  begin
    g_peffect.Endpass;
    g_peffect._end;
  end;

end;

//ez a bal kéz egyébként

function TFegyv.jkez(afegyv:word;astate:byte;szogy:single = 0):TD3DXVector3;
var
  bol:boolean;
  mat1, mat2:TD3DMatrix;
begin
  bol:=(0 = (astate and MSTAT_CSIPO));

  // if bol then afegyv:=afegyv+256;

  if bol then //ZOOOOOOOOM
    case afegyv of
      FEGYV_M4A1, FEGYV_G_M4A1:result:=D3DXVector3(-0.05, 1.41, -0.45);
      FEGYV_MPG, FEGYV_G_MPG:result:=D3DXVector3(-0.05, 1.4, -0.45);
      FEGYV_M82A1, FEGYV_G_M82A1:result:=D3DXVector3(-0.05, 1.42, -0.6);
      FEGYV_QUAD, FEGYV_G_QUAD:result:=D3DXVector3(0, 1.25, -0.48);
      FEGYV_X72, FEGYV_G_X72:result:=D3DXVector3(-0.05, 1.27, -0.45);
      FEGYV_NOOB, FEGYV_G_NOOB:result:=D3DXVector3(-0.05, 1.17, -0.35);
      FEGYV_LAW, FEGYV_G_LAW:result:=D3DXVector3(-0.2, 1.37, -0.45);
      FEGYV_MP5A3, FEGYV_G_MP5A3:result:=D3DXVector3(-0.05, 1.41, -0.45);
      FEGYV_H31_T:result:=D3DXVector3(-0.1, 1.37, -0.45);
      FEGYV_H31_G:result:=D3DXVector3(-0.1, 1.37, -0.45);
      FEGYV_BM3, FEGYV_G_BM3:result:=vec3add2(D3DXVector3(-0.05, 1.08, -0.48), D3DXVector3(0, 0.36, -0.14));
      FEGYV_HPL, FEGYV_G_HPL:result:=vec3add2(D3DXVector3(-0.05, 1.02, -0.37), D3DXVector3(0, 0.32, -0.11));
    else result:=D3DXVector3(-0.05, 1.37, -0.45);
    end
  else
    case afegyv of
      FEGYV_M4A1, FEGYV_G_M4A1:result:=D3DXVector3(-0.05, 1.11, -0.45);
      FEGYV_MPG, FEGYV_G_MPG:result:=D3DXVector3(-0.05, 1.08, -0.45);
      FEGYV_M82A1, FEGYV_G_M82A1:result:=vec3add2(D3DXVector3(-0.05, 1.42, -0.6), D3DXVector3(0, -0.35, 0.15));
      FEGYV_NOOB, FEGYV_G_NOOB:result:=D3DXVector3(0.15, 1.0, -0.13);
      FEGYV_LAW, FEGYV_G_LAW:result:=D3DXVector3(-0.15, 1.07, -0.27);
      FEGYV_MP5A3, FEGYV_G_MP5A3:result:=D3DXVector3(-0.05, 1.10, -0.45);
      FEGYV_QUAD, FEGYV_G_QUAD:result:=D3DXVector3(-0.00, 1.01, -0.28);
      FEGYV_X72, FEGYV_G_X72:result:=D3DXVector3(0.01, 1, -0.37);
      FEGYV_H31_T:result:=D3DXVector3(-0.05, 1.07, -0.27);
      FEGYV_H31_G:result:=D3DXVector3(-0.05, 1.07, -0.27);
      FEGYV_BM3, FEGYV_G_BM3:result:=D3DXVector3(-0.05, 1.08, -0.48);
      FEGYV_HPL, FEGYV_G_HPL:result:=D3DXVector3(-0.05, 1.02, -0.37);
    else result:=D3DXVector3(-0.05, 1.05, -0.45);
    end;

  if szogy <> 0 then
    if bol then begin
      D3DXMatrixTranslation(mat1, 0, -vallmag2, 0);
      D3DXMatrixRotationX(mat2, szogy);
      D3DXVec3TransformCoord(result, result, mat1);
      D3DXVec3TransformCoord(result, result, mat2);
      D3DXMatrixTranslation(mat1, 0, vallmag2, 0);
      D3DXVec3TransformCoord(result, result, mat1);
    end
    else
    begin
      D3DXMatrixTranslation(mat1, 0, -vallmag, 0);
      D3DXMatrixRotationX(mat2, szogy);
      D3DXVec3TransformCoord(result, result, mat1);
      D3DXVec3TransformCoord(result, result, mat2);
      D3DXMatrixTranslation(mat1, 0, vallmag, 0);
      D3DXVec3TransformCoord(result, result, mat1);
    end;

  if 0<(astate and MSTAT_GUGGOL) then
  begin
    result.y:=result.y - 0.5;
  end;
  //if (astate and MSTAT_MASK) = 7 then
  //  result := D3DXVector3(-0.00, 2.00, -0.28);

end;

//ez meg a jobb kéz

function TFegyv.bkez(afegyv:word;astate:byte;szogy:single = 0):TD3DXVector3;
var
  bol:boolean;
  mat1, mat2:TD3DMatrix;
begin
  bol:=0 = (astate and MSTAT_CSIPO);

  // if bol then afegyv:=afegyv+256;

  if bol then
    case afegyv of
      FEGYV_M4A1, FEGYV_G_M4A1, FEGYV_B_M4A1:result:=D3DXVector3(-0.05, 1.37, -0.27);
      FEGYV_M82A1, FEGYV_G_M82A1, FEGYV_B_M82A1:result:=D3DXVector3(-0.05, 1.4, -0.35);
      FEGYV_NOOB, FEGYV_G_NOOB, FEGYV_B_NOOB:result:=D3DXVector3(-0.05, 1.15, -0.10);
      FEGYV_LAW, FEGYV_G_LAW, FEGYV_B_LAW:result:=D3DXVector3(-0.2, 1.35, -0.27);
	    FEGYV_QUAD, FEGYV_G_QUAD, FEGYV_B_QUAD:result:=D3DXVector3(0, 1.28, -0.13);
	    FEGYV_X72, FEGYV_G_X72, FEGYV_B_X72:result:=D3DXVector3(-0.05, 1.27, -0.15);
      FEGYV_BM3, FEGYV_G_BM3, FEGYV_B_BM3:result:=vec3add2(D3DXVector3(-0.07, 1.06, -0.21), D3DXVector3(0.03, 0.36, -0.14));
      FEGYV_HPL, FEGYV_G_HPL, FEGYV_B_HPL:result:=vec3add2(D3DXVector3(-0.05, 1.055, -0.17), D3DXVector3(0, 0.32, -0.11));

	    FEGYV_H31_T:result:=D3DXVector3(-0.1, 1.35, -0.27);
      FEGYV_H31_G:result:=D3DXVector3(-0.1, 1.35, -0.27);
    else result:=D3DXVector3(-0.05, 1.35, -0.27);
    end
  else
    case afegyv of
	
      FEGYV_M4A1, FEGYV_G_M4A1, FEGYV_B_M4A1:result:=D3DXVector3(-0.05, 1.07, -0.27);
      FEGYV_M82A1, FEGYV_G_M82A1, FEGYV_B_M82A1:result:=vec3add2(D3DXVector3(-0.05, 1.4, -0.35), D3DXVector3(0, -0.35, 0.15));
      FEGYV_NOOB, FEGYV_G_NOOB, FEGYV_B_NOOB:result:=D3DXVector3(-0.17, 1.07, -0.1);
      FEGYV_LAW, FEGYV_G_LAW, FEGYV_B_LAW:result:=D3DXVector3(-0.25, 1.1, -0.45);
      FEGYV_QUAD, FEGYV_G_QUAD, FEGYV_B_QUAD:result:=D3DXVector3(-0.05, 1.00, -0.07);
      FEGYV_X72, FEGYV_G_X72, FEGYV_B_X72:result:=D3DXVector3(-0.07, 0.95, -0.15);
      FEGYV_BM3, FEGYV_G_BM3, FEGYV_B_BM3:result:=D3DXVector3(-0.07, 1.06, -0.21);
      FEGYV_HPL, FEGYV_G_HPL, FEGYV_B_HPL:result:=D3DXVector3(-0.05, 1.055, -0.17);
	  
	    FEGYV_H31_T:result:=D3DXVector3(-0.15, 1.1, -0.45);
      FEGYV_H31_G:result:=D3DXVector3(-0.15, 1.1, -0.45);
    else result:=D3DXVector3(-0.05, 1.05, -0.27);
    end;

  if szogy <> 0 then
    if bol then begin
      D3DXMatrixTranslation(mat1, 0, -vallmag2, 0);
      D3DXMatrixRotationX(mat2, szogy);
      D3DXVec3TransformCoord(result, result, mat1);
      D3DXVec3TransformCoord(result, result, mat2);
      D3DXMatrixTranslation(mat1, 0, vallmag2, 0);
      D3DXVec3TransformCoord(result, result, mat1);
    end
    else
    begin
      D3DXMatrixTranslation(mat1, 0, -vallmag, 0);
      D3DXMatrixRotationX(mat2, szogy);
      D3DXVec3TransformCoord(result, result, mat1);
      D3DXVec3TransformCoord(result, result, mat2);
      D3DXMatrixTranslation(mat1, 0, vallmag, 0);
      D3DXVec3TransformCoord(result, result, mat1);
    end;

  if 0<(astate and MSTAT_GUGGOL) then
  begin
    result.y:=result.y - 0.5;
  end;

  //if (astate and MSTAT_MASK) = 7 then
  //  result := D3DXVector3(-0.00, 2.00, -0.28);


end;



procedure TFegyv.drawscope(mit:byte);
begin
  g_pd3dDevice.SetFVF(D3DFVF_CUSTOMVERTEX);
  //    g_pd3dDevice.SetIndices(g_pIB);

  g_pd3dDevice.SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_MODULATE);
  g_pd3dDevice.SetTextureStageState(1, D3DTSS_COLOROP, D3DTOP_MODULATE);

  g_pd3dDevice.SetTextureStageState(0, D3DTSS_COLORARG1, D3DTA_TEXTURE);
  g_pd3dDevice.SetTextureStageState(0, D3DTSS_COLORARG2, D3DTA_DIFFUSE);

  g_pd3dDevice.SetRenderState(D3DRS_SRCBLEND, D3DBLEND_SRCALPHA);
  g_pd3dDevice.SetRenderState(D3DRS_DESTBLEND, D3DBLEND_INVSRCALPHA);
  g_pd3ddevice.SetRenderState(D3DRS_BLENDOP, D3DBLENDOP_ADD);

  g_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAARG1, D3DTA_TEXTURE);
  g_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAARG2, D3DTA_DIFFUSE);
  g_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_SELECTARG1);

  g_pd3dDevice.SetRenderState(D3DRS_AMBIENT, $FFFFFFFF);
  g_pd3dDevice.SetRenderState(D3DRS_ALPHABLENDENABLE, iFalse);

  case mit of
    FEGYV_M82A1:M82A1.drawscope;
    FEGYV_HPL:HPL.drawscope;
  end;
end;

procedure TFegyv.preparealpha;
begin
  g_pd3dDevice.SetRenderState(D3DRS_CULLMODE, D3DCULL_NONE);
  g_pd3dDevice.SetRenderState(D3DRS_AMBIENT, $FFFFFFFF);
  g_pd3ddevice.SetRenderState(D3DRS_BLENDFACTOR, $FFFFFFFF);
  g_pd3dDevice.SetRenderState(D3DRS_ALPHABLENDENABLE, iTrue);
  g_pd3dDevice.SetRenderState(D3DRS_ZWriteENABLE, iTrue);
  g_pd3dDevice.SetRenderState(D3DRS_LIGHTING, iFalse);


  g_pd3dDevice.SetRenderState(D3DRS_SRCBLEND, D3DBLEND_SRCALPHA);
  //  g_pd3dDevice.SetRenderState(D3DRS_DESTBLEND,D3DBLEND_SRCALPHA);
  g_pd3dDevice.SetRenderState(D3DRS_DESTBLEND, D3DBLEND_ONE);
  g_pd3ddevice.SetRenderState(D3DRS_BLENDOP, D3DBLENDOP_ADD);

  g_pd3dDevice.SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_MODULATE);
  //  g_pd3dDevice.SetTextureStageState(0,D3DTSS_COLOROP,D3DTOP_SELECTARG1);
  g_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_MODULATE);

  g_pd3dDevice.SetTextureStageState(0, D3DTSS_COLORARG1, D3DTA_DIFFUSE);
  g_pd3dDevice.SetTextureStageState(0, D3DTSS_COLORARG2, D3DTA_TEXTURE);
  g_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAARG1, D3DTA_DIFFUSE);
  g_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAARG2, D3DTA_TEXTURE);

  g_pd3dDevice.SetSamplerState(0, D3DSAMP_ADDRESSU, D3DTADDRESS_MIRROR);
  g_pd3dDevice.SetSamplerState(0, D3DSAMP_ADDRESSV, D3DTADDRESS_MIRROR);
  g_pd3dDevice.SetSamplerState(0, D3DSAMP_MIPFILTER, D3DTEXF_POINT);
end;

procedure Tfegyv.drawfegyeffekt(mit:byte;mekkora:single;szog:single);
begin

  //  mekkora:=clip(0,1,mekkora);

  case mit of
    FEGYV_M4A1:M4A1.drawmuzzle(mekkora);
    FEGYV_M82A1:M82A1.drawmuzzle(mekkora);
    FEGYV_MP5A3:MP5A3.drawmuzzle(mekkora);
    // FEGYV_LAW:LAW.drawmuzzle(mekkora);
    FEGYV_MPG:MPG.drawmuzzle(mekkora, szog);
    FEGYV_QUAD:QUADRO.drawmuzzle(mekkora, szog);
    //FEGYV_NOOB:Noobcannon.drawmuzzle(mekkora);
    FEGYV_X72:X72.drawmuzzle(mekkora);
    FEGYV_BM3:BM3.drawmuzzle(mekkora);
    FEGYV_HPL:HPL.drawmuzzle(mekkora);
  end;
end;

procedure TFegyv.FlushFegyeffekt;
const
  PUFFER_MERET = 5000;
var
  pVert:PCustomvertexarray;
  curr, mpgstart, x72start:integer;
label
  unlock;
begin
  mpgstart:=0;x72start:=0;
  g_pd3ddevice.SetTransform(D3DTS_WORLD, identmatr);


  curr:=0;
  if FAILED(g_pVB.Lock(0, PUFFER_MERET * sizeof(Tcustomvertex), Pointer(pVert), D3DLOCK_DISCARD))
    then Exit;

  if curr + length(M4A1.muzzez) >= PUFFER_MERET then goto unlock;
  copymemory(@(pVert[curr]), @(M4A1.muzzez[0]), length(M4A1.muzzez) * sizeof(TCustomvertex));
  inc(curr, length(M4A1.muzzez));
  setlength(M4A1.muzzez, 0);

  if curr + length(M82A1.muzzez) >= PUFFER_MERET then goto unlock;
  copymemory(@(pVert[curr]), @(M82A1.muzzez[0]), length(M82A1.muzzez) * sizeof(TCustomvertex));
  inc(curr, length(M82A1.muzzez));
  setlength(M82A1.muzzez, 0);

  if curr + length(MP5A3.muzzez) >= PUFFER_MERET then goto unlock;
  copymemory(@(pVert[curr]), @(MP5A3.muzzez[0]), length(MP5A3.muzzez) * sizeof(TCustomvertex));
  inc(curr, length(MP5A3.muzzez));
  setlength(MP5A3.muzzez, 0);

  if curr + length(BM3.muzzez) >= PUFFER_MERET then goto unlock;
  copymemory(@(pVert[curr]), @(BM3.muzzez[0]), length(BM3.muzzez) * sizeof(TCustomvertex));
  inc(curr, length(BM3.muzzez));
  setlength(BM3.muzzez, 0);

  mpgstart:=curr;

  if curr + length(MPG.muzzez) >= PUFFER_MERET then goto unlock;
  copymemory(@(pVert[curr]), @(MPG.muzzez[0]), length(MPG.muzzez) * sizeof(TCustomvertex));
  inc(curr, length(MPG.muzzez));
  setlength(MPG.muzzez, 0);

  if curr + length(QUADRO.muzzez) >= PUFFER_MERET then goto unlock;
  copymemory(@(pVert[curr]), @(QUADRO.muzzez[0]), length(QUADRO.muzzez) * sizeof(TCustomvertex));
  inc(curr, length(QUADRO.muzzez));
  setlength(QUADRO.muzzez, 0);

  x72start:=curr;

  if curr + length(X72.muzzez) >= PUFFER_MERET then goto unlock;
  copymemory(@(pVert[curr]), @(X72.muzzez[0]), length(X72.muzzez) * sizeof(TCustomvertex));
  inc(curr, length(X72.muzzez));
  setlength(X72.muzzez, 0);
  unlock:
  g_pVB.Unlock;
  g_pd3ddevice.SetStreamSource(0, g_pVB, 0, sizeof(TCustomvertex));
  g_pd3ddevice.SetFVF(D3DFVF_CUSTOMVERTEX);

  if (mpgstart div 3) > 0 then begin
    g_pd3ddevice.settexture(0, gunmuztex);
    g_pd3ddevice.DrawPrimitive(D3DPT_TRIANGLELIST, 0, mpgstart div 3); //megáll
  end;

  if ((x72start - mpgstart) div 33) > 0 then begin
    g_pd3ddevice.settexture(0, mpgmuztex);
    g_pd3ddevice.DrawPrimitive(D3DPT_TRIANGLELIST, mpgstart, (x72start - mpgstart) div 3);
  end;

  if ((curr - x72start) div 3) > 0 then begin
    g_pd3ddevice.settexture(0, x72muztex);
    g_pd3ddevice.DrawPrimitive(D3DPT_TRIANGLELIST, x72start, (curr - x72start) div 3);
  end;

  setlength(M4A1.muzzez, 0);

end;

procedure TFegyv.unpreparealpha;
begin
  g_pd3dDevice.SetRenderState(D3DRS_CULLMODE, D3DCULL_CCW);
  g_pd3dDevice.SetRenderState(D3DRS_ALPHABLENDENABLE, iFalse);
  g_pd3dDevice.SetRenderState(D3DRS_ZWriteENABLE, iTrue);
  g_pd3dDevice.SetSamplerState(0, D3DSAMP_MIPFILTER, D3DTEXF_LINEAR);

end;


destructor TFegyv.Destroy;
begin
  M4A1.destroy;
  MPG.destroy;
  //TODO ALL THE WEPS SHOULD BE HERE!
  if g_pd3ddevice <> nil then
    g_pd3ddevice:=nil;
  setlength(M4proj, 0);
  setlength(Mpgproj, 0);
  inherited;
end;
end.

