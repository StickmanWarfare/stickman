unit stickApi;

interface

  uses
    Classes,
    Windows,
    SysUtils,
    //
    IdHTTP,
    IdURI,
    //
    multiplayer,
    qjson,
    Sentry,
    Scripts,
    Utils;

  const
    BASE_URL = 'https://stickman.hu/api?mode=';
    NL = AnsiString(#13#10);


  type TApiResponse = record
    success: boolean;
    data: TQJSON;
  end;

  type TApi = class(TObject)
    public
      class function GET(const route: string): TApiResponse;
  end;

  procedure printTop(const args: array of const);
  procedure printRank(const args: array of const);
  procedure printKoth(const args: array of const);

  
implementation

{
  HELPER FUNCTIONS
}
function StreamToString(Stream: TMemoryStream): String;
var
    len: Integer;
begin
    len := Stream.Size - Stream.Position;
    SetLength(Result, len);
    if len > 0 then Stream.ReadBuffer(Result[1], len);
end;

{
  TApi
}
class function TApi.GET(const route: string): TApiResponse;
var
  url: string;
begin
  try
    url := TIdURI.URLEncode(BASE_URL + KillMeUtils.unhungaryify(route));
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

end.

