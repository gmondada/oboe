cmake_minimum_required(VERSION 4.0.0)

#cmake_file_api(
#  QUERY
#  API_VERSION 1
#  CODEMODEL 2.3
#  TOOLCHAINS 1
#)

# Set the name of the project and store it in PROJECT_NAME. Also set the following variables:
# PROJECT_SOURCE_DIR (usually the root directory where Oboe has been cloned e.g.)
# PROJECT_BINARY_DIR (usually the containing project's binary directory,
# e.g. ${OBOE_HOME}/samples/RhythmGame/.externalNativeBuild/cmake/ndkExtractorDebug/x86/oboe-bin)
project(oboe)

set (oboe_sources
    src/aaudio/AAudioLoader.cpp
    src/aaudio/AudioStreamAAudio.cpp
    src/common/AdpfWrapper.cpp
    src/common/AudioSourceCaller.cpp
    src/common/AudioStream.cpp
    src/common/AudioStreamBuilder.cpp
    src/common/DataConversionFlowGraph.cpp
    src/common/FilterAudioStream.cpp
    src/common/FixedBlockAdapter.cpp
    src/common/FixedBlockReader.cpp
    src/common/FixedBlockWriter.cpp
    src/common/LatencyTuner.cpp
    src/common/OboeExtensions.cpp
    src/common/SourceFloatCaller.cpp
    src/common/SourceI16Caller.cpp
    src/common/SourceI24Caller.cpp
    src/common/SourceI32Caller.cpp
    src/common/Utilities.cpp
    src/common/QuirksManager.cpp
    src/fifo/FifoBuffer.cpp
    src/fifo/FifoController.cpp
    src/fifo/FifoControllerBase.cpp
    src/fifo/FifoControllerIndirect.cpp
    src/flowgraph/FlowGraphNode.cpp
    src/flowgraph/ChannelCountConverter.cpp
    src/flowgraph/ClipToRange.cpp
    src/flowgraph/Limiter.cpp
    src/flowgraph/ManyToMultiConverter.cpp
    src/flowgraph/MonoBlend.cpp
    src/flowgraph/MonoToMultiConverter.cpp
    src/flowgraph/MultiToManyConverter.cpp
    src/flowgraph/MultiToMonoConverter.cpp
    src/flowgraph/RampLinear.cpp
    src/flowgraph/SampleRateConverter.cpp
    src/flowgraph/SinkFloat.cpp
    src/flowgraph/SinkI16.cpp
    src/flowgraph/SinkI24.cpp
    src/flowgraph/SinkI32.cpp
    src/flowgraph/SinkI8_24.cpp
    src/flowgraph/SourceFloat.cpp
    src/flowgraph/SourceI16.cpp
    src/flowgraph/SourceI24.cpp
    src/flowgraph/SourceI32.cpp
    src/flowgraph/SourceI8_24.cpp
    src/flowgraph/resampler/IntegerRatio.cpp
    src/flowgraph/resampler/LinearResampler.cpp
    src/flowgraph/resampler/MultiChannelResampler.cpp
    src/flowgraph/resampler/PolyphaseResampler.cpp
    src/flowgraph/resampler/PolyphaseResamplerMono.cpp
    src/flowgraph/resampler/PolyphaseResamplerStereo.cpp
    src/flowgraph/resampler/SincResampler.cpp
    src/flowgraph/resampler/SincResamplerStereo.cpp
    src/opensles/AudioInputStreamOpenSLES.cpp
    src/opensles/AudioOutputStreamOpenSLES.cpp
    src/opensles/AudioStreamBuffered.cpp
    src/opensles/AudioStreamOpenSLES.cpp
    src/opensles/EngineOpenSLES.cpp
    src/opensles/OpenSLESUtilities.cpp
    src/opensles/OutputMixerOpenSLES.cpp
    src/common/StabilizedCallback.cpp
    src/common/Trace.cpp
    src/common/Version.cpp
    )

add_library(oboe ${oboe_sources})

# Specify directories which the compiler should look for headers
target_include_directories(oboe
        PRIVATE src
        PUBLIC include)

# Compile Flags:
#     Enable -Werror when building debug config
#     Enable -Ofast
target_compile_options(oboe
        PRIVATE
        -std=c++17
        -Wall
        -Wextra-semi
        -Wshadow
        -Wshadow-field
        "$<$<CONFIG:RELEASE>:-Ofast>"
        "$<$<CONFIG:DEBUG>:-O3>"
        "$<$<CONFIG:DEBUG>:-Werror>")

# Enable logging of D,V for debug builds
target_compile_definitions(oboe PUBLIC $<$<CONFIG:DEBUG>:OBOE_ENABLE_LOGGING=1>)

option(OBOE_DO_NOT_DEFINE_OPENSL_ES_CONSTANTS "Do not define OpenSLES constants" OFF)
target_compile_definitions(oboe PRIVATE $<$<BOOL:${OBOE_DO_NOT_DEFINE_OPENSL_ES_CONSTANTS}>:DO_NOT_DEFINE_OPENSL_ES_CONSTANTS=1>)

target_link_libraries(oboe PRIVATE log OpenSLES)
target_link_options(oboe PRIVATE "-Wl,-z,max-page-size=16384")

# When installing oboe put the libraries in the lib/<ABI> folder e.g. lib/arm64-v8a
install(TARGETS oboe
        LIBRARY DESTINATION lib/${ANDROID_ABI}
        ARCHIVE DESTINATION lib/${ANDROID_ABI})

# Also install the headers
install(DIRECTORY include/oboe DESTINATION include)


get_target_property(srcs oboe SOURCES)
message(STATUS "Sources for oboe: ${srcs}")

get_target_property(incs oboe INTERFACE_INCLUDE_DIRECTORIES)
message(STATUS "Include directories for oboe: ${incs}")

get_target_property(incs2 oboe INCLUDE_DIRECTORIES)
message(STATUS "Include directories for oboe: ${incs2}")

# Print all CMake variables in JSON format
file(WRITE "${CMAKE_BINARY_DIR}/cmake_vars.json" "{\n")
get_cmake_property(_variableNames VARIABLES)
list(APPEND _variableNames SOURCES)
list(APPEND _variableNames INTERFACE_INCLUDE_DIRECTORIES)
list(APPEND _variableNames INCLUDE_DIRECTORIES)
list(LENGTH _variableNames _varCount)
set(_varIndex 0)
foreach(_variableName ${_variableNames})
        # Escape quotes and backslashes for JSON
        string(REPLACE "\\" "\\\\" _value "${${_variableName}}")
        string(REPLACE "\"" "\\\"" _value "${_value}")
        string(REPLACE "\n" "\\n" _value "${_value}")
        # Print variable as JSON key-value pair
        file(APPEND "${CMAKE_BINARY_DIR}/cmake_vars.json" "  \"${_variableName}\": \"${_value}\"")
        math(EXPR _varIndex "${_varIndex} + 1")
        if(NOT _varIndex EQUAL _varCount)
                file(APPEND "${CMAKE_BINARY_DIR}/cmake_vars.json" ",\n")
        else()
                file(APPEND "${CMAKE_BINARY_DIR}/cmake_vars.json" "\n")
        endif()
endforeach()
file(APPEND "${CMAKE_BINARY_DIR}/cmake_vars.json" "}\n")
message(STATUS "CMake variables written to ${CMAKE_BINARY_DIR}/cmake_vars.json")

# List all properties for the 'oboe' target
get_target_property(_all_properties oboe VARIABLES)
message(STATUS "All properties for target 'oboe': ${_all_properties}")

# Print all target properties and their values
foreach(_prop ${_all_properties})
        get_target_property(_prop_value oboe ${_prop})
        message(STATUS "Target property '${_prop}': ${_prop_value}")
endforeach()
