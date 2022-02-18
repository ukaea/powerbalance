package Utilities

  model CombiTimeTable
    "Extends basic CombiTimeTable with additional functionality"
    extends Modelica.Blocks.Sources.CombiTimeTable;
    final parameter Real value_max = getTimeTableYmax(tableID);
  equation
  end CombiTimeTable;
  
  function getTimeTableYmax
    "Return maximum ordinate value of 1-dim. table where first column is time"
    extends Modelica.Icons.Function;
    input Modelica.Blocks.Types.ExternalCombiTimeTable tableID;
    output Real yMax "Maximum ordinate value in table";
    external"C" yMax = maximumValue(tableID)
      annotation (Include="#include <getTimeTableYmax.c>");
  end getTimeTableYmax;

end Utilities;
