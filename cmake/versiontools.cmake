
find_package(Git)

if( Git_FOUND )
  execute_process(
    COMMAND ${GIT_EXECUTABLE} rev-parse --abbrev-ref HEAD
    WORKING_DIRECTORY ${SURGESRC}
    OUTPUT_VARIABLE GIT_BRANCH
    OUTPUT_STRIP_TRAILING_WHITESPACE
    )

  execute_process(
    COMMAND ${GIT_EXECUTABLE} log -1 --format=%h
    WORKING_DIRECTORY ${SURGESRC}
    OUTPUT_VARIABLE GIT_COMMIT_HASH
    OUTPUT_STRIP_TRAILING_WHITESPACE
    )
else()
  message( WARNING "Git isn't present in your path. Setting hashes to defaults" )
  set( GIT_BRANCH "git-not-present" )
  set( GIT_COMMIT_HASH "git-not-present" )
endif()

if( WIN32 )
  set( SURGE_BUILD_ARCH "Intel" )
else()
  execute_process(
    COMMAND uname -m
    OUTPUT_VARIABLE SURGE_BUILD_ARCH
    OUTPUT_STRIP_TRAILING_WHITESPACE
  )
endif()

cmake_host_system_information(RESULT SURGE_BUILD_FQDN QUERY FQDN )

message( STATUS "Setting up surge version" )
message( STATUS "  git hash is ${GIT_COMMIT_HASH} and branch is ${GIT_BRANCH}" )
message( STATUS "  buildhost is ${SURGE_BUILD_FQDN}" )
message( STATUS "  buildarch is ${SURGE_BUILD_ARCH}" )

if( ${AZURE_PIPELINE} )
  message( STATUS "Azure Pipeline Build" )
  set( lpipeline "pipeline" )
else()
  message( STATUS "Developer Local Build" )
  set( lpipeline "local" )
endif()

if(${GIT_BRANCH} STREQUAL "main" )
  if( ${AZURE_PIPELINE} )
    set( lverpatch "nightly" )
  else()
    set( lverpatch "main" )
  endif()
  set( lverrel "999" )
else()
  string( FIND ${GIT_BRANCH} "release/" RLOC )
  if( ${RLOC} EQUAL 0 )
    message( STATUS "Configuring a Release Build" )
    string( SUBSTRING ${GIT_BRANCH} 12 100 RV ) # that's release slash 1.7.
    set( lverpatch "stable-${RV}" )
    string( FIND ${RV} "." DLOC )
    if( NOT ( DLOC EQUAL -1 ) )
      string( SUBSTRING ${RV} 0 ${DLOC} LRV ) # that's release slash 1.7.
      set( lverrel ${LRV} )
    else()
      set( lverrel "99" )
    endif()
  else()
    set( lverpatch ${GIT_BRANCH} )
    set( lverrel "1000" )
  endif()
endif()

set( SURGE_FULL_VERSION "${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}.${lverpatch}.${GIT_COMMIT_HASH}" )
set( SURGE_MAJOR_VERSION "${PROJECT_VERSION_MAJOR}" )
set( SURGE_SUB_VERSION "${PROJECT_VERSION_MINOR}" )
set( SURGE_RELEASE_VERSION "${lverpatch}" )
set( SURGE_RELEASE_NUMBER "${lverrel}" )
set( SURGE_BUILD_HASH "${GIT_COMMIT_HASH}" )
set( SURGE_BUILD_LOCATION "${lpipeline}" )

string( TIMESTAMP SURGE_BUILD_DATE "%Y-%m-%d" )
string( TIMESTAMP SURGE_BUILD_TIME "%H:%M:%S" )

message( STATUS "Using SURGE_VERSION=${SURGE_FULL_VERSION}" )

message( STATUS "Configuring ${SURGEBLD}/geninclude/version.cpp" )
configure_file( ${SURGESRC}/src/common/version.cpp.in
  ${SURGEBLD}/geninclude/version.cpp )

if( WIN32 )
  message( STATUS "Configuring surgeversion.rc" )
  configure_file( ${SURGESRC}/src/windows/surgeversion.rc.in
    ${SURGEBLD}/geninclude/surgeversion.rc
    )
endif()
  
