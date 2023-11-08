workspace("vpc")
	configuration{"debug", "release"}
	location("..")
	architecture("x86")
	filter{"configurations:debug"}
		defines{"DEBUG"}
		symbols("On")

	filter{"configurations:release"}
		defines{"NDEBUG"}
		optimize("On")

	filter {}

project("vpc")
	kind("ConsoleApp")
	language("C++")
	location("../src")

	files{
		"../src/interfaces/interfaces.cpp"
		"../src/"
	}