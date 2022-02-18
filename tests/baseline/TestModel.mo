model UnitTestModel
  Real x;
  parameter Real __beta = 0.3;
equation
  der(x) = 1-__beta*x;
end UnitTestModel;
