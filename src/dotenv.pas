unit dotenv;

interface

  type TDotenv = class (TObject)
    private
      _isDev: Boolean;
      _hasChecksumCheck: Boolean;
    public
      property isDev: Boolean read _isDev;
      property hasChecksumCheck: Boolean read _hasChecksumCheck;
      //
      constructor Create(dev, checksumCheck: boolean);
  end;


implementation

constructor TDotenv.Create(dev, checksumCheck: boolean);
begin
  _isDev := dev;
  _hasChecksumCheck := checksumcheck;
end;

end.
