unit stickApi;

interface

  uses
    Classes,
    Windows,
    SysUtils,
    //
    IdHTTP,
    IdURI,
    IdMultipartFormData,
    IdIOHandler,
    IdSSLOpenSSL,
    //
    multiplayer,
    qjson,
    Sentry,
    Scripts,
    Utils;

  const
    PROTOCOL = 'https://';
    BASE_URL = 'stickman.hu/api?mode=';
    NL = AnsiString(#13#10);


  type TApiResponse = record
    success: boolean;
    data: TQJSON;
  end;

  type TApi = class(TObject)
    public
      class function GET(const route: string): TApiResponse;  
      class function POST(const route: string; const data: TIdMultipartFormDataStream): TApiResponse;
  end;

  procedure printTop(const args: array of const);
  procedure printRank(const args: array of const);
  procedure printKoth(const args: array of const);
  procedure sendBotKills(const args: array of const);

  
implementation

{
  TApi
}
class function TApi.GET(const route: string): TApiResponse;
var
  url: string;
begin
  try
    url := TIdURI.URLEncode(PROTOCOL + BASE_URL + KillMeUtils.unhungaryify(route));
    sentryModule.addBreadcrumb(makeBreadcrumb('[GET] ' + url));

    result.success := true;
    result.data := TQJSON.CreateFromHTTP(url);
  except
    on E:Exception do
    begin
      sentryModule.addBreadcrumb(makeBreadcrumb('[GET] Failed: ' + url + ' - with ' + E.Message));
      result.success := false;
      result.data := TQJSON.Create;
    end
  end;
end;

class function TApi.POST(const route: string; const data: TIdMultipartFormDataStream): TApiResponse;
var
  url: string; 
  postResponse: string;
  HTTPClient: TIdHTTP;
  IdSSLIOHandler: TIdSSLIOHandlerSocketOpenSSL;
begin
  try
    url := TIdURI.URLEncode(PROTOCOL + BASE_URL + KillMeUtils.unhungaryify(route));
    sentryModule.addBreadcrumb(makeBreadcrumb('[POST] ' + url));
                               
    HTTPClient := TIdHTTP.Create(nil);

    IdSSLIOHandler := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
    IdSSLIOHandler.SSLOptions.SSLVersions := [sslvTLSv1,sslvTLSv1_1,sslvTLSv1_2];
    HTTPClient.IOHandler := IdSSLIOHandler;

    postResponse := HTTPClient.Post(url, data);
    postResponse := stringreplace(postResponse, '\', '', [rfReplaceAll]);

    result.success := true;
    result.data := TQJSON.CreateFromString(postResponse);
  except
    on E:Exception do
    begin
      sentryModule.addBreadcrumb(makeBreadcrumb('[POST] Failed: ' + url + ' - with ' + E.Message));
      result.success := false;
      result.data := TQJSON.Create;
    end
  end;
end;

//-----------------------------------------------------------------------------
// THREADS
//-----------------------------------------------------------------------------

procedure printTop(const args: array of const);
var
  i: Integer;
  route, output, line, nev, pont: string;
  response: TApiResponse;
begin
  route := VariantUtils.VarRecToStr(args[0]);

  try
    response := TApi.GET(route);

    if response.success then
    begin
      for i := 0 to 9 do
      begin
        nev := response.data.getString(['data', i, 'nev']);
        if length(nev) = 0 then nev := '-';

        pont := response.data.getString(['data', i, 'pont']);
        if length(pont) = 0 then pont := '';

        line := intToStr(i + 1) + '. ' + nev + ' ' + pont;
        output := output + NL + line;
       end;
       scriptsHandler.evalscriptline('display ' + output);
    end;

  except
    sentryModule.addBreadcrumb(makeBreadcrumb('printTop failed on ' + route));
    //TODO: reportError(E, msg) helyette majd ha nem egy file lesz az output
  end;

end;

procedure printRank(const args: array of const);
var
  route, output, username, mode: string;
  response: TApiResponse;
begin
  try
    username := VariantUtils.VarRecToStr(args[0]);
    mode := VariantUtils.VarRecToStr(args[1]);
    route := 'rank&nev=' + username + '&type=' + mode;

    response := TApi.GET(route);

    if response.success then
    begin
      output := response.data.getString(['data', 'rank']);

      scriptsHandler.evalscriptline('display ' + output);
    end;

  except
    on E:Exception do
    begin
      sentryModule.addBreadcrumb(makeBreadcrumb('printRank failed on ' + route));
      //TODO: reportError(E, msg) helyette majd ha nem egy file lesz az output
    end;
  end;
end;

procedure printKoth(const args: array of const);
var               
  i: Integer;
  output, line, nev, pont, mode: string;
  response: TApiResponse;
begin
  try
    mode := VariantUtils.VarRecToStr(args[0]);
    response := TApi.GET(mode);

    if response.success then
    begin
      for i := 0 to 9 do
      begin
        nev := response.data.getString(['data', i, 'nev']);
        if length(nev) = 0 then nev := '-';

        pont := response.data.getString(['data', i, 'pont']);
        if length(pont) = 0 then pont := '';

        line := intToStr(i + 1) + '. ' + nev + ' ' + pont;
        output := output + NL + line;
       end;
       
       scriptsHandler.evalscriptline('display ' + output);
    end;
  except
    on E:Exception do
    begin
      sentryModule.addBreadcrumb(makeBreadcrumb('printKoth failed on ' + mode));
      //TODO: reportError(E, msg) helyette majd ha nem egy file lesz az output
    end;
  end;
end;

procedure sendBotKills(const args: array of const);
var
  route, kills: string;
  response: TApiResponse;
  postData: TIdMultiPartFormDataStream;
begin
  route := 'botkill';

  try
    kills := VariantUtils.VarRecToStr(args[0]);

    postData := TIdMultiPartFormDataStream.Create;
    postData.AddFormField('form[nev]', KillMeUtils.unhungaryify(multisc.nev));
    postData.AddFormField('form[kills]', kills);

    response := TApi.POST(route, postData);
  except
    on E:Exception do
    begin
      sentryModule.addBreadcrumb(makeBreadcrumb('sendBotKills failed'));
      //TODO: reportError(E, msg) helyette majd ha nem egy file lesz az output
    end;
  end;
end;

end.

