-- license:BSD-3-Clause
-- copyright-holders:MAMEdev Team

---------------------------------------------------------------------------
--
--   main.lua
--
--   Rules for building main binary
--
---------------------------------------------------------------------------

function mainProject(_target, _subtarget)
if (_OPTIONS["SOURCES"] == nil) then
	if (_target == _subtarget) then
		project (_target)
	else
		if (_subtarget=="mess") then
			project (_subtarget)
		else
			project (_target .. _subtarget)
		end
	end
else
	project (_subtarget)
end
	uuid (os.uuid(_target .."_" .. _subtarget))
	kind "ConsoleApp"

	configuration { "android*" }
		targetprefix "lib"
		targetname "main"
		targetextension ".so"
		linkoptions {
			"-shared",
			"-Wl,-soname,libmain.so"
		}
		links {
			"EGL",
			"GLESv1_CM",
			"GLESv2",
			"SDL2",
		}

	configuration {  }

	addprojectflags()
	flags {
		"NoManifest",
		"Symbols", -- always include minimum symbols for executables
	}

	if _OPTIONS["SYMBOLS"] then
		configuration { "mingw*" }
			postbuildcommands {
				"$(SILENT) echo Dumping symbols.",
				"$(SILENT) objdump --section=.text --line-numbers --syms --demangle $(TARGET) >$(subst .exe,.sym,$(TARGET))"
			}
	end

	configuration { "x64", "Release" }
		targetsuffix ""
		if _OPTIONS["PROFILE"] then
			targetsuffix "p"
		end

	configuration { "x64", "Debug" }
		targetsuffix "d"
		if _OPTIONS["PROFILE"] then
			targetsuffix "dp"
		end

	configuration { "x32", "Release" }
		targetsuffix "32"
		if _OPTIONS["PROFILE"] then
			targetsuffix "32p"
		end

	configuration { "x32", "Debug" }
		targetsuffix "32d"
		if _OPTIONS["PROFILE"] then
			targetsuffix "32dp"
		end

	configuration { "mingw*" or "vs20*" }
		targetextension ".exe"

	configuration { "asmjs" }
		targetextension ".bc"
		if os.getenv("EMSCRIPTEN") then
			local emccopts = ""
				.. " -O" .. _OPTIONS["OPTIMIZE"]
				.. " -s USE_SDL=2"
				.. " -s USE_SDL_TTF=2"
				.. " --memory-init-file 0"
				.. " -s DISABLE_EXCEPTION_CATCHING=2"
				.. " -s EXCEPTION_CATCHING_WHITELIST=\"['__ZN15running_machine17start_all_devicesEv','__ZN12cli_frontend7executeEiPPc','__ZN8chd_file11open_commonEb','__ZN8chd_file13read_metadataEjjRNSt3__212basic_stringIcNS0_11char_traitsIcEENS0_9allocatorIcEEEE','__ZN8chd_file13read_metadataEjjRNSt3__26vectorIhNS0_9allocatorIhEEEE','__ZNK19netlist_mame_device19base_validity_checkER16validity_checker']\""
				.. " -s EXPORTED_FUNCTIONS=\"['_main', '_malloc', '__ZN15running_machine30emscripten_get_running_machineEv', '__ZN15running_machine17emscripten_get_uiEv', '__ZN15running_machine20emscripten_get_soundEv', '__ZN15mame_ui_manager12set_show_fpsEb', '__ZNK15mame_ui_manager8show_fpsEv', '__ZN13sound_manager4muteEbh', '_SDL_PauseAudio', '_SDL_SendKeyboardKey', '__ZN15running_machine15emscripten_saveEPKc', '__ZN15running_machine15emscripten_loadEPKc', '__ZN15running_machine21emscripten_hard_resetEv', '__ZN15running_machine21emscripten_soft_resetEv', '__ZN15running_machine15emscripten_exitEv']\""
				.. " -s EXTRA_EXPORTED_RUNTIME_METHODS=\"['cwrap']\""
				.. " -s ERROR_ON_UNDEFINED_SYMBOLS=0"
				.. " -s USE_WEBGL2=1"
				.. " -s LEGACY_GL_EMULATION=1"
				.. " -s GL_UNSAFE_OPTS=0"
				.. " --pre-js " .. _MAKE.esc(MAME_DIR) .. "src/osd/modules/sound/js_sound.js"
				.. " --post-js " .. _MAKE.esc(MAME_DIR) .. "scripts/resources/emscripten/emscripten_post.js"
				.. " --embed-file " .. _MAKE.esc(MAME_DIR) .. "bgfx/chains@bgfx/chains"
				.. " --embed-file " .. _MAKE.esc(MAME_DIR) .. "bgfx/effects@bgfx/effects"
				.. " --embed-file " .. _MAKE.esc(MAME_DIR) .. "bgfx/shaders/essl@bgfx/shaders/essl"
				.. " --embed-file " .. _MAKE.esc(MAME_DIR) .. "artwork/bgfx@artwork/bgfx"
				.. " --embed-file " .. _MAKE.esc(MAME_DIR) .. "artwork/slot-mask.png@artwork/slot-mask.png"

			if _OPTIONS["SYMBOLS"]~=nil and _OPTIONS["SYMBOLS"]~="0" then
				emccopts = emccopts
					.. " -g" .. _OPTIONS["SYMLEVEL"]
					.. " -s DEMANGLE_SUPPORT=1"
			end

			if _OPTIONS["WEBASSEMBLY"] then
				emccopts = emccopts
					.. " -s WASM=" .. _OPTIONS["WEBASSEMBLY"]
			else
				emccopts = emccopts
					.. " -s WASM=1"
			end

			if _OPTIONS["WEBASSEMBLY"]~=nil and _OPTIONS["WEBASSEMBLY"]=="0" then
				-- define a fixed memory size because allowing memory growth disables asm.js optimizations
				emccopts = emccopts
					.. " -s ALLOW_MEMORY_GROWTH=0"
					.. " -s TOTAL_MEMORY=268435456"
			else
				emccopts = emccopts
					.. " -s ALLOW_MEMORY_GROWTH=1"
			end

			if _OPTIONS["ARCHOPTS"] then
				emccopts = emccopts .. " " .. _OPTIONS["ARCHOPTS"]
			end

			postbuildcommands {
				--os.getenv("EMSCRIPTEN") .. "/emcc " .. emccopts .. " $(TARGET) -o " .. _MAKE.esc(MAME_DIR) .. _OPTIONS["target"] .. _OPTIONS["subtarget"] .. ".js",
				os.getenv("EMSCRIPTEN") .. "/emcc " .. emccopts .. " $(TARGET) -o " .. _MAKE.esc(MAME_DIR) .. _OPTIONS["target"] .. _OPTIONS["subtarget"] .. ".html",
			}
		end

	configuration { }

	if _OPTIONS["targetos"]=="android" then
		includedirs {
			MAME_DIR .. "3rdparty/SDL2/include",
		}

		files {
			MAME_DIR .. "3rdparty/SDL2/src/main/android/SDL_android_main.c",
		}
		targetsuffix ""
		if _OPTIONS["SEPARATE_BIN"]~="1" then
			if _OPTIONS["PLATFORM"]=="arm" then
				targetdir(MAME_DIR .. "android-project/app/src/main/libs/armeabi-v7a")
			end
			if _OPTIONS["PLATFORM"]=="arm64" then
				targetdir(MAME_DIR .. "android-project/app/src/main/libs/arm64-v8a")
			end
			if _OPTIONS["PLATFORM"]=="x86" then
				targetdir(MAME_DIR .. "android-project/app/src/main/libs/x86")
			end
			if _OPTIONS["PLATFORM"]=="x64" then
				targetdir(MAME_DIR .. "android-project/app/src/main/libs/x86_64")
			end
		end
	else
		if _OPTIONS["SEPARATE_BIN"]~="1" then
			targetdir(MAME_DIR)
		end
	end

if (STANDALONE~=true) then
	findfunction("linkProjects_" .. _OPTIONS["target"] .. "_" .. _OPTIONS["subtarget"])(_OPTIONS["target"], _OPTIONS["subtarget"])
end
	links {
		"osd_" .. _OPTIONS["osd"],
	}
	links {
		"qtdbg_" .. _OPTIONS["osd"],
	}
if (STANDALONE~=true) then
	links {
		"frontend",
	}
end
	links {
		"optional",
		"emu",
	}
--if (STANDALONE~=true) then
	links {
		"formats",
	}
--end
if #disasm_files > 0 then
	links {
		"dasm",
	}
end
if (MACHINES["NETLIST"]~=null) then
	links {
		"netlist",
	}
end
	links {
		"utils",
		ext_lib("expat"),
		"softfloat",
		"softfloat3",
		"wdlfft",
		"ymfm",
		ext_lib("jpeg"),
		"7z",
	}
if not _OPTIONS["FORCE_DRC_C_BACKEND"] then
	links {
		"asmjit",
	}
end
if (STANDALONE~=true) then
	links {
		ext_lib("lua"),
		"lualibs",
		"linenoise",
	}
end
	links {
		ext_lib("zlib"),
		ext_lib("flac"),
		ext_lib("utf8proc"),
	}
if (STANDALONE~=true) then
	links {
		ext_lib("sqlite3"),
	}
end

	if _OPTIONS["NO_USE_PORTAUDIO"]~="1" then
		links {
			ext_lib("portaudio"),
		}
		if _OPTIONS["targetos"]=="windows" then
			links {
				"setupapi",
			}
		end
	end
	if _OPTIONS["NO_USE_MIDI"]~="1" then
		links {
			ext_lib("portmidi"),
		}
	end
	links {
		"bgfx",
		"bimg",
		"bx",
		"ocore_" .. _OPTIONS["osd"],
	}

	override_resources = false;

	maintargetosdoptions(_target,_subtarget)

	includedirs {
		MAME_DIR .. "src/osd",
		MAME_DIR .. "src/emu",
		MAME_DIR .. "src/devices",
		MAME_DIR .. "src/" .. _target,
		MAME_DIR .. "src/lib",
		MAME_DIR .. "src/lib/util",
		MAME_DIR .. "3rdparty",
		GEN_DIR  .. _target .. "/layout",
		GEN_DIR  .. "resource",
		ext_includedir("zlib"),
		ext_includedir("flac"),
	}


if (STANDALONE==true) then
	standalone();
end

if (STANDALONE~=true) then
	if _OPTIONS["targetos"]=="macosx" and (not override_resources) then
		linkoptions {
			"-sectcreate __TEXT __info_plist " .. _MAKE.esc(GEN_DIR) .. "resource/" .. _subtarget .. "-Info.plist"
		}
		custombuildtask {
			{ GEN_DIR .. "version.cpp" ,  GEN_DIR .. "resource/" .. _subtarget .. "-Info.plist",    {  MAME_DIR .. "scripts/build/verinfo.py" }, {"@echo Emitting " .. _subtarget .. "-Info.plist" .. "...",    PYTHON .. " $(1)  -p -b " .. _subtarget .. " $(<) > $(@)" }},
		}
		dependency {
			{ "$(TARGET)" ,  GEN_DIR  .. "resource/" .. _subtarget .. "-Info.plist", true  },
		}

	end
	local rctarget = _subtarget

	if _OPTIONS["targetos"]=="windows" and (not override_resources) then
		rcfile = MAME_DIR .. "scripts/resources/windows/" .. _subtarget .. "/" .. rctarget ..".rc"
		if os.isfile(rcfile) then
			files {
				rcfile,
			}
			dependency {
				{ "$(OBJDIR)/".._subtarget ..".res" ,  GEN_DIR  .. "resource/" .. rctarget .. "vers.rc", true  },
			}
		else
			rctarget = "mame"
			files {
				MAME_DIR .. "scripts/resources/windows/mame/mame.rc",
			}
			dependency {
				{ "$(OBJDIR)/mame.res" ,  GEN_DIR  .. "resource/" .. rctarget .. "vers.rc", true  },
			}
		end
	end

	local mainfile = MAME_DIR .. "src/".._target .."/" .. _subtarget ..".cpp"
	if not os.isfile(mainfile) then
		mainfile = MAME_DIR .. "src/".._target .."/" .. _target ..".cpp"
	end
	files {
		mainfile,
		MAME_DIR .. "src/version.cpp",
		GEN_DIR  .. _target .. "/" .. _subtarget .."/drivlist.cpp",
	}

	if (_OPTIONS["SOURCES"] == nil) then

		if os.isfile(MAME_DIR .. "src/".._target .."/" .. _subtarget ..".flt") then
			dependency {
			{
				GEN_DIR  .. _target .. "/" .. _subtarget .."/drivlist.cpp",  MAME_DIR .. "src/".._target .."/" .. _target ..".lst", true },
			}
			custombuildtask {
				{ MAME_DIR .. "src/".._target .."/" .. _subtarget ..".flt" ,  GEN_DIR  .. _target .. "/" .. _subtarget .."/drivlist.cpp",    {  MAME_DIR .. "scripts/build/makedep.py", MAME_DIR .. "src/".._target .."/" .. _target ..".lst"  }, {"@echo Building driver list...",    PYTHON .. " $(1) driverlist $(2) -f $(<) > $(@)" }},
			}
		else
			if os.isfile(MAME_DIR .. "src/".._target .."/" .. _subtarget ..".lst") then
				custombuildtask {
					{ MAME_DIR .. "src/".._target .."/" .. _subtarget ..".lst" ,  GEN_DIR  .. _target .. "/" .. _subtarget .."/drivlist.cpp",    {  MAME_DIR .. "scripts/build/makedep.py" }, {"@echo Building driver list...",    PYTHON .. " $(1) driverlist $(<) > $(@)" }},
				}
			else
				dependency {
				{
					GEN_DIR  .. _target .. "/" .. _target .."/drivlist.cpp",  MAME_DIR .. "src/".._target .."/" .. _target ..".lst", true },
				}
				custombuildtask {
					{ MAME_DIR .. "src/".._target .."/" .. _target ..".lst" ,  GEN_DIR  .. _target .. "/" .. _target .."/drivlist.cpp",    {  MAME_DIR .. "scripts/build/makedep.py" }, {"@echo Building driver list...",    PYTHON .. " $(1) driverlist $(<) > $(@)" }},
				}
			end
		end
	end

	if (_OPTIONS["SOURCES"] ~= nil) then
			dependency {
			{
				GEN_DIR  .. _target .. "/" .. _subtarget .."/drivlist.cpp",  MAME_DIR .. "src/".._target .."/" .. _target ..".lst", true },
			}
			custombuildtask {
				{ GEN_DIR .. _target .."/" .. _subtarget ..".flt" ,  GEN_DIR  .. _target .. "/" .. _subtarget .."/drivlist.cpp",    {  MAME_DIR .. "scripts/build/makedep.py", MAME_DIR .. "src/".._target .."/" .. _target ..".lst"  }, {"@echo Building driver list...",    PYTHON .. " $(1) driverlist $(2) -f $(<) > $(@)" }},
			}
	end

	configuration { "mingw*" }
		custombuildtask {
--			{ GEN_DIR .. "version.cpp" ,  GEN_DIR  .. "resource/" .. rctarget .. "vers.rc",    {  MAME_DIR .. "scripts/build/verinfo.py" }, {"@echo Emitting " .. rctarget .. "vers.rc" .. "...",    PYTHON .. " $(1)  -r -b " .. rctarget .. " $(<) > $(@)" }},
			{ MAME_DIR .. "src/version.cpp" ,  GEN_DIR  .. "resource/" .. rctarget .. "vers.rc",    {  MAME_DIR .. "scripts/build/verinfo.py" }, {"@echo Emitting " .. rctarget .. "vers.rc" .. "...",    PYTHON .. " $(1)  -r -b " .. rctarget .. " $(<) > $(@)" }},
		}

	configuration { "vs20*" }
		prebuildcommands {
			"mkdir \"" .. path.translate(GEN_DIR  .. "resource/","\\") .. "\" 2>NUL",
			"@echo Emitting ".. rctarget .. "vers.rc...",
			PYTHON .. " \"" .. path.translate(MAME_DIR .. "scripts/build/verinfo.py","\\") .. "\" -r -b " .. rctarget .. " \"" .. path.translate(GEN_DIR .. "version.cpp","\\") .. "\" > \"" .. path.translate(GEN_DIR  .. "resource/" .. rctarget .. "vers.rc", "\\") .. "\"" ,
		}
end

	configuration { }

	if _OPTIONS["DEBUG_DIR"]~=nil then
		debugdir(_OPTIONS["DEBUG_DIR"])
	else
		debugdir (MAME_DIR)
	end
	if _OPTIONS["DEBUG_ARGS"]~=nil then
		debugargs (_OPTIONS["DEBUG_ARGS"])
	else
		debugargs ("-window")
	end

end
