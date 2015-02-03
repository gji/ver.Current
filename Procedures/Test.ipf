#pragma rtGlobals=3		// Use modern global access method and strict wave access.

#pragma rtGlobals=3		// Use modern global access method and strict wave access.
function poisson()
	String fldrSav0= GetDataFolder(1)
	SetDatafolder root:test	
	variable i=0
	wave PoissonWave
	Wave POissonHist
//	Make/o/N=500 PoissonWave
//	make/o/n=50 PoissonHist
	Redimension/N=300 PoissonWave
//
//	for(i=0;i!=DimSize(PoissonWave,0);i+=1)
//		PoissonWave[i]		= poissonNoise(0)
//	endfor

// HALF B D
//	for(i=0;i!=DimSize(PoissonWave,0)/2;i+=1)
//		PoissonWave[i]		= poissonNoise(0)
//	endfor
//	for(i=DimSize(PoissonWave,0)/2;i!=DimSize(PoissonWave,0);i+=1)
//		PoissonWave[i]		= poissonNoise(10)
//	endfor


// EQUAL SUPERPOSITION two ion
	for(i=0;i!=DimSize(PoissonWave,0)/3;i+=1)
		PoissonWave[i]		= poissonNoise(0)
	endfor
	for(i=DimSize(PoissonWave,0)/3;i!=DimSize(PoissonWave,0)*2/3;i+=1)
		PoissonWave[i]		= poissonNoise(10)
	endfor
	for(i=DimSize(PoissonWave,0)*2/3;i!=DimSize(PoissonWave,0);i+=1)
		PoissonWave[i]		= poissonNoise(20)
	endfor

// HALF BB DD
//	for(i=0;i!=DimSize(PoissonWave,0)/2;i+=1)
//		PoissonWave[i]		= poissonNoise(0)
//	endfor
//	for(i=DimSize(PoissonWave,0)/2;i!=DimSize(PoissonWave,0);i+=1)
//		PoissonWave[i]		= poissonNoise(30)
//	endfor	
	
// HALF BD DD
//	for(i=0;i!=DimSize(PoissonWave,0);i+=1)
//		PoissonWave[i]		= poissonNoise(0)
//	endfor
//	for(i=DimSize(PoissonWave,0)*3/4;i!=DimSize(PoissonWave,0);i+=1)
//		PoissonWave[i]		= poissonNoise(10)
//	endfor
	
// HALF BD BB
//	for(i=0;i!=DimSize(PoissonWave,0)/2;i+=1)
//		PoissonWave[i]		= poissonNoise(30)
//	endfor
//	for(i=DimSize(PoissonWave,0)/2;i!=DimSize(PoissonWave,0)*3/4;i+=1)
//		PoissonWave[i]		= poissonNoise(10)
//	endfor
//	for(i=DimSize(PoissonWave,0)*3/4;i!=DimSize(PoissonWave,0);i+=1)
//		PoissonWave[i]		= poissonNoise(0)
//	endfor		
		
	Histogram/B={0,1,50} PoissonWave, PoissonHist
	PoissonHist=PoissonHist/DimSize(PoissonWave,0)
//	POissonWave=PoissonWave/Sum(PoissonWave)
	SetDataFolder fldrSav0
end


function poissonScan(k)
	Variable k
	String fldrSav0= GetDataFolder(1)
	SetDatafolder root:test	
	variable i=0
	wave PoissonWave
	Wave POissonHist
//	Make/o/N=500 PoissonWave
//	make/o/n=50 PoissonHist
	Redimension/N=300 PoissonWave

	for(i=0;i!=DimSize(PoissonWave,0);i+=1)
		PoissonWave[i]		= poissonNoise(k)
	endfor

	SetDataFolder fldrSav0
end

function StringTest()
	string subject ="alignmentBasisFit_01"
	String regExp ="([[:alpha:]]+)_ ([[:digit:]]+)"
	string name, firstBit
	SplitString /E=(regExp) subject, name, firstBit
	print regExp
	print subject
	print Firstbit
end

Function SplitDataString(subject)
	String subject 
	String regExp = "([[:alpha:]]+)_([[:digit:]]+)"
	String data, channel
	SplitString /E=(regExp) subject, data, channel
	variable num=str2num(channel)
	return num
End

