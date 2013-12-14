module M3

import lang::java::jdt::m3::Core;
import util::Benchmark;
import ValueIO;

public void createM3(int apiLevel, loc eclipseProject = |project://Android/src|) { // add project after run
	//loc eclipseProject = |project://Android<"<apiLevel>">/src|;
	M3 m3Model = createM3FromEclipseProject(eclipseProject);
	writeTextValueFile(|project://Android/m3/| + "lvl<apiLevel>-<getMilliTime()>.txt", m3Model);
	writeBinaryValueFile(|project://Android/m3/| + "lvl<apiLevel>-<getMilliTime()>.bin", m3Model);
}