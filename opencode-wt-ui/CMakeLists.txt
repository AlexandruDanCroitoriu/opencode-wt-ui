cmake_minimum_required(VERSION 3.13...3.22)
include(FetchContent)
include(ExternalProject)

project(app)

# Set number of parallel build jobs to number of available processors
include(ProcessorCount)
ProcessorCount(N)
if(NOT N EQUAL 0)
  set(CMAKE_BUILD_PARALLEL_LEVEL ${N})
endif()

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -g -pthread")

# Define DEBUG macro for Debug build type and RELEASE for Release builds.
if(CMAKE_BUILD_TYPE MATCHES Debug)
  add_compile_definitions(DEBUG)
elseif(CMAKE_BUILD_TYPE MATCHES Release)
  add_compile_definitions(RELEASE)
endif()

set(RLIB --docroot ../../ -c ../../wt_config.xml --http-address 0.0.0.0 --http-port 9020)
set(SOURCE_DIR ${PROJECT_SOURCE_DIR}/src/)

include_directories(${SOURCE_DIR})


FetchContent_Declare(json URL https://github.com/nlohmann/json/releases/download/v3.12.0/json.tar.xz)
FetchContent_MakeAvailable(json)

# FetchContent_Declare(cpr GIT_REPOSITORY https://github.com/libcpr/cpr.git GIT_TAG da40186618909b1a7363d4e4495aa899c6e0eb75) 
# FetchContent_MakeAvailable(cpr)

# # Whisper.cpp integration
# FetchContent_Declare(
#     whisper
#     GIT_REPOSITORY https://github.com/ggerganov/whisper.cpp.git
#     GIT_TAG v1.5.4
# )
# FetchContent_MakeAvailable(whisper)

# ./cpp-wt --docroot ../ –config ./wt_config.xml --http-address 0.0.0.0 --http-port 9020

set(SOURCES
    ${SOURCE_DIR}/main.cpp
    
    ${SOURCE_DIR}/000_Server/Server.cpp
    
    ${SOURCE_DIR}/001_App/App.cpp
    
    ${SOURCE_DIR}/004_Theme/Theme.cpp
    ${SOURCE_DIR}/004_Theme/DarkModeToggle.cpp
    
    # ${SOURCE_DIR}/005_Components/ComponentsDisplay.cpp
    # ${SOURCE_DIR}/005_Components/Button.cpp
    ${SOURCE_DIR}/005_Components/DragBar.cpp
    ${SOURCE_DIR}/005_Components/MonacoEditor.cpp
    # ${SOURCE_DIR}/005_Components/VoiceRecorder.cpp
    # ${SOURCE_DIR}/005_Components/WhisperWrapper.cpp
    
    ${SOURCE_DIR}/006_Stylus/Stylus.cpp
    
    ${SOURCE_DIR}/007_Opencode/Opencode.cpp
    ${SOURCE_DIR}/007_Opencode/Sessions.cpp
    
    ${SOURCE_DIR}/002_Dbo/Session.cpp
    ${SOURCE_DIR}/002_Dbo/Tables/User.cpp
    ${SOURCE_DIR}/002_Dbo/Tables/Permission.cpp

  ${SOURCE_DIR}/003_Auth/AuthWidget.cpp
  ${SOURCE_DIR}/003_Auth/RegistrationView.cpp
  ${SOURCE_DIR}/003_Auth/UserDetailsModel.cpp

    # ${SOURCE_DIR}/006-Navigation/Navigation.cpp
    
    # ${SOURCE_DIR}/007-UserSettings/UserSettings.cpp

    # ${SOURCE_DIR}/008-AboutMe/AboutMe.cpp


    # ${SOURCE_DIR}/101-StarWarsApi/StarWarsApi.cpp

)

add_executable(${PROJECT_NAME} ${SOURCES})

# Ensure compile-time macros are available for multi-config generators as well
target_compile_definitions(${PROJECT_NAME}
  PRIVATE
    $<$<CONFIG:Debug>:DEBUG>
    $<$<CONFIG:Release>:RELEASE>
)

target_link_libraries(${PROJECT_NAME} 
    wthttp
    wt
    wtdbo
    wtdbosqlite3
    wtdbopostgres
    # boost_regex
    # cpr::cpr
    nlohmann_json::nlohmann_json
    # whisper
)

# Set runtime library path so the executable can find the shared libraries
# set_target_properties(${PROJECT_NAME} PROPERTIES
#     INSTALL_RPATH "${CMAKE_CURRENT_BINARY_DIR}/_deps/cpr-build/cpr:${CMAKE_CURRENT_BINARY_DIR}/_deps/whisper-build"
#     BUILD_WITH_INSTALL_RPATH TRUE
#     INSTALL_RPATH_USE_LINK_PATH TRUE
# )

# Add pthread for threading support (if not already present)
# find_package(Threads REQUIRED)
# target_link_libraries(${PROJECT_NAME} Threads::Threads)

# Platform-specific libraries

# if(UNIX AND NOT APPLE)
#     target_link_libraries(${PROJECT_NAME} dl)
# endif()

# add_custom_target(run
#     COMMAND ${CMAKE_COMMAND} ${RLIB}
#     # COMMAND ${CMAKE_COMMAND} -E env LD_LIBRARY_PATH=${CMAKE_CURRENT_BINARY_DIR}/_deps/cpr-build/cpr:${CMAKE_CURRENT_BINARY_DIR}/_deps/whisper-build:$ENV{LD_LIBRARY_PATH} $<TARGET_FILE:${PROJECT_NAME}> ${RLIB}
#     # DEPENDS ${PROJECT_NAME}
#     # WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
#     # COMMENT "Running ${PROJECT_NAME} with proper library paths"
# )


# )


add_custom_target(run
    COMMAND $<TARGET_FILE:${PROJECT_NAME}> ${RLIB}
    DEPENDS ${PROJECT_NAME}
    WORKING_DIRECTORY ${CMAKE_PROJECT_DIR}
)