program tarrayexample;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Classes
  { add your units here },strings,DynamicArray;
  
type
Tarrayexampleclass=class
private
procedure doDestroyItem(Sender: Tobject; Col,Row: Integer;var Item: Pointer);

end;

procedure Tarrayexampleclass.doDestroyItem(Sender: Tobject; Col,Row: Integer;
  var Item: Pointer);
begin
  strdispose(Item);
end;


var FCols: Tarray;
var ex:Tarrayexampleclass;

begin
FCols:= TArray.Create;
ex:= Tarrayexampleclass.Create;
FCols.OnDestroyItem:=@ex.doDestroyItem;
FCols.SetLength(8,8);
//FCols.OnNewItem:=@doNewItem;
FCols.arr[0,0]:=StrNew('string1');
FCols.arr[4,7]:=StrNew('string2');
FCols.arr[4,3]:=StrNew('string3');
writeln('0,0:'+Pchar(FCols.arr[0,0]));
writeln('4,7:'+Pchar(FCols.arr[4,7]));
FCols.MoveColRow(true,4,5);
writeln('after moving column 4 to 5');
writeln('5,7:'+Pchar(FCols.arr[5,7]));
writeln('before exchanging row 7 and 3:');
writeln('5,3:'+Pchar(FCols.arr[5,3]));
writeln('5,7:'+Pchar(FCols.arr[5,7]));
FCols.ExchangeColRow(false,7,3);
writeln('after exchanging row 7 and 3:');
writeln('5,3:'+Pchar(FCols.arr[5,3]));
writeln('5,7:'+Pchar(FCols.arr[5,7]));
FCols.DeleteColRow(true,5);
writeln('after deleting column 5:');
try
 writeln('5,3:'+Pchar(FCols.arr[5,3])); //this raises an exception
except
 writeln ('An exception has taken place be because 5,3 does not exist.');
end;
try
 writeln('5,7:'+Pchar(FCols.arr[5,7])); //this raises an exception
except
 writeln ('An exception has taken place be because 5,7 does not exist.');
end;
FCols.Clear; writeln('after clear:');
try
 writeln('4,7:'+Pchar(FCols.arr[4,7])); //this raises an exception
except
 writeln ('An exception has taken place be because 4,7 does not exist.');
end;
FCols.Destroy;
ex.Destroy;
readln;
end.


