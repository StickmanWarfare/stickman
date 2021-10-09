unit Redux;

interface

  uses Typestuff, MutableObject;

  type

    TActionType = string;

    TAction = record
      key: TActionType;
      payload: TMutableObject;
    end;

    // TActionCreator = function(value: TMutableObject): TAction;

    TState = TMutableObject;

    TReducer = function(state: TState; action: TAction): TState;

    //TSubscribe = procedure(callback: TProcedure);

    //TDispatch = procedure(action: TAction);

    //TGetState = function: TState;

    TStore = class
      private
        __state: TState;
        __reducer: TReducer;
        __listeners: TCallbackArray;
      public
        function getState(): TState;
        procedure subscribe(callback: TCallback);
        procedure dispatch(action: TAction);
        constructor Create(initialState: TState; reducer: TReducer);
    end;

    //TODO: function makeCombinedStore(stores: array of stores): TStore;

var
  appStore: TStore;

implementation

constructor TStore.Create(initialState: TState; reducer: TReducer);
begin
  inherited Create;

  __state := initialState;
  __reducer := reducer;
end; 

function TStore.getState(): TState;
begin
  result := __state;
end;

procedure TStore.subscribe(callback: TCallback);
begin
  setlength(__listeners, length(__listeners) + 1);
  __listeners[high(__listeners)] := callback;
end;

procedure TStore.dispatch(action: TAction);
var
  i: Integer;
begin
  __reducer(getState(), action);

  //TODO: optimize with key<->listener dict
  for i := 0 to high(__listeners) do
  begin
    __listeners[i]();
  end;
end;

end.

