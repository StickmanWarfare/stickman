unit Sentry;

interface

  uses
    SysUtils, 
    MMSystem,
    Windows,
    //
    Typestuff,
    MutableObject;

  const
    MAX_BREADCRUMBS = 50;

  type TSentryMetadata = record
    isDev: boolean;
    version: Integer;
    checksum: Cardinal;
  end;

  type TSentryBreadcrumb = record
    timestamp: string;
    msg: string;
    data: TMutableObject;
  end;

  type TSentry = class (TOBject)
    private
      _output: Textfile;
      _metadata: TSentryMetadata;
      _breadcrumbs: array of TSentryBreadcrumb;
    published
      constructor Create;
      procedure addBreadcrumb(crumb: TSentryBreadcrumb);
      procedure reportError(err: Exception; msg: string);
  end;

  function makeBreadcrumb(msg: string): TSentryBreadcrumb; overload;
  function makeBreadcrumb(msg: string; data: TMutableObject): TSentryBreadcrumb; overload;

var
  sentryModule: TSentry;

implementation

function metadataToJSON(metadata: TSentryMetadata): string; forward;
function breadcrumbToJSON(crumb: TSentryBreadcrumb): string; forward;

function makeBreadcrumb(msg: string): TSentryBreadcrumb; overload;
begin
  result.timestamp := formatdatetime('YYYY-MM-DD hh:mm:ss', now);
  result.msg := msg;
  result.data := TMutableObject.Create(true);
end;

function makeBreadcrumb(msg: string; data: TMutableObject): TSentryBreadcrumb; overload;
begin
  result.timestamp := formatdatetime('YYYY-MM-DD hh:mm:ss', now);
  result.msg := msg;
  result.data := data;
end;

constructor TSentry.Create;
begin
  with _metadata do
  begin
    isDev := {$IFDEF undebug} false {$ELSE} true {$ENDIF};
    version := PROG_VER;
    checksum := datachecksum;
  end;
end;

procedure TSentry.addBreadcrumb(crumb: TSentryBreadcrumb);
var
  i: Integer;
begin
  //can append
  if length(_breadcrumbs) < MAX_BREADCRUMBS then
  begin
    setlength(_breadcrumbs, succ(length(_breadcrumbs)));
    _breadcrumbs[high(_breadcrumbs)] := crumb;

    exit;
  end;

  //shift
  for i := low(_breadcrumbs) to pred(high(_breadcrumbs)) do
    _breadcrumbs[i] := _breadcrumbs[succ(i)];

  setlength(_breadcrumbs, MAX_BREADCRUMBS);
  _breadcrumbs[high(_breadcrumbs)] := crumb;
end;

//TODO: actual JSON writer
procedure TSentry.reportError(err: Exception; msg: string);
var
  json: string;
  i: Integer;
begin
  //open output file
  assignfile(_output, 'sentry.json');
  rewrite(_output);

  //make contents
  json := '{';

  //error and message
  json := json + '"error": "' + err.message + '"';
  json := json + ', "message": "' + msg + '"';
  json := json + ', "laststate": "' + laststate + '"';

  //metadata
  json := json + ', "metadata": ' + metadataToJSON(_metadata);

  //breadcrumbs
  json := json + ', "breadcrumbs": [';
  for i := low(_breadcrumbs) to high(_breadcrumbs) do
  begin
    if i > low(_breadcrumbs) then
      json := json + ', ';

    json := json + breadcrumbToJSON(_breadcrumbs[i]);
  end;

  //breadcrumbs end
  json := json + ']';

  //content end
  json := json + '}';

  //write and close output file
  write(_output, json);
  flush(_output);
  closefile(_output);

  setlength(_breadcrumbs, 0);
end;

function metadataToJSON(metadata: TSentryMetadata): string;
begin
  result := '{';

  if metadata.isDev then
    result := result + '"mode": "dev"'
  else
    result := result + '"mode": "prod"';

  result := result + ', "version": "' + intToStr(metadata.version) + '"';
  result := result + ', "datachecksum": "' + intToHex(metadata.checksum, 8) + '"';

  result := result + '}';
end;


function breadcrumbToJSON(crumb: TSentryBreadcrumb): string;
begin
  result := '{';

  result := result + '"timestamp": "' + crumb.timestamp + '"';
  result := result + ', "message": "' + crumb.msg + '"';
  if not crumb.data.isEmpty then
    result := result + ', "data": ' + crumb.data.toJSON;

  result := result + '}';
end;

end.
