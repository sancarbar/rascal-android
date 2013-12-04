module M3

import lang::java::jdt::m3::Core;
import util::Benchmark;
import ValueIO;

public void createM3(loc eclipseProject = |project://Android|) {
	M3 m3Model = createM3FromEclipseProject(eclipseProject);
	writeTextValueFile(|project://Android/m3/| + "<getMilliTime()>.txt", m3Model);
}