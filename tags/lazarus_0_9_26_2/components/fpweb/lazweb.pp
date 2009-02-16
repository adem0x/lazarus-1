{
  Copyright (C) 2007 Michael Van Canneyt

  This library is free software; you can redistribute it and/or modify it
  under the terms of the GNU Library General Public License as published by
  the Free Software Foundation; either version 2 of the License, or (at your
  option) any later version.

  This program is distributed in the hope that it will be useful, but WITHOUT
  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
  FITNESS FOR A PARTICULAR PURPOSE. See the GNU Library General Public License
  for more details.

  You should have received a copy of the GNU Library General Public License
  along with this library; if not, write to the Free Software Foundation,
  Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
}
{$mode objfpc}
{$H+}
unit lazweb;

Interface

uses Classes,lresources;

function InitResourceComponent(Instance: TComponent;
  RootAncestor: TClass): Boolean;

Implementation

function InitResourceComponent(Instance: TComponent;
  RootAncestor: TClass): Boolean;
begin
  Result:=InitLazResourceComponent(Instance,RootAncestor);
end;

initialization
  RegisterInitComponentHandler(TComponent,@InitResourceComponent);
  
end.
