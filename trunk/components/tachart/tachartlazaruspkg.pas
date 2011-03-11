{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit TAChartLazarusPkg; 

interface

uses
  TAGraph, TAChartAxis, TAChartUtils, TACustomSeries, TASources, TADbSource, 
  TASeries, TASeriesEditor, TASubcomponentsEditor, TATools, TATransformations, 
  TATypes, TADrawUtils, TAMultiSeries, TALegend, TAStyles, TAFuncSeries, 
  TALegendPanel, TARadialSeries, TACustomSource, TAGeometry, LazarusPackageIntf;

implementation

procedure Register; 
begin
  RegisterUnit('TAGraph', @TAGraph.Register); 
  RegisterUnit('TASources', @TASources.Register); 
  RegisterUnit('TADbSource', @TADbSource.Register); 
  RegisterUnit('TASeriesEditor', @TASeriesEditor.Register); 
  RegisterUnit('TATools', @TATools.Register); 
  RegisterUnit('TATransformations', @TATransformations.Register); 
  RegisterUnit('TAStyles', @TAStyles.Register); 
  RegisterUnit('TALegendPanel', @TALegendPanel.Register); 
end; 

initialization
  RegisterPackage('TAChartLazarusPkg', @Register); 
end.
