#pragma rtGlobals=1		// Use modern global access method.

Function Poisson(w,x) : FitFunc
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = Exp(-k)*k^ceil(x)/factorial(ceil(x))
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 1
	//CurveFitDialog/ w[0] = k

	return Exp(-w[0])*w[0]^ceil(x)/factorial(ceil(x))
End

Function DoublePoisson(w,x) : FitFunc
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = (1+(1-t)/(1+k*t)*(1+1/(k*t)))*Sqrt(t)*Exp(-k*t)*Exp(-ceil(x))*(ceil(x)^ceil(x))/factorial(ceil(x))*(Exp(1)*k/ceil(x))^(t*ceil(x))
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 2
	//CurveFitDialog/ w[0] = k
	//CurveFitDialog/ w[1] = t

	return (1+(1-w[1])/(1+w[0]*w[1])*(1+1/(w[0]*w[1])))*Sqrt(w[1])*Exp(-w[0]*w[1])*Exp(-ceil(x))*(ceil(x)^ceil(x))/factorial(ceil(x))*(Exp(1)*w[0]/ceil(x))^(w[1]*ceil(x))
End