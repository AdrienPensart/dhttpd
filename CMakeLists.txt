cmake_minimum_required(VERSION 2.8.1)

PROJECT (dhttpd D )
SET (CMAKE_D_COMPILER "dmd" )
SET( GLOBAL_DMD_DEFS "-w -I${CMAKE_CURRENT_SOURCE_DIR}/src -version=tracing" )

# Don't use ADD_DEFINITIONS() with a mixed C + D project
# since that adds the same flags to both C and D builds.
# Also, the D linker preference is set to 40, which is
# higher than C++ (30) and C (10).  This causes CMAKE
# to use the D linker in mixed linking cases.
# Append our own definitions to the defaults.
SET( CMAKE_D_FLAGS "${CMAKE_D_FLAGS} ${GLOBAL_DMD_DEFS}" )

file(GLOB_RECURSE files ${CMAKE_CURRENT_SOURCE_DIR} "src/*.d")
add_executable(dhttpd ${files})
target_link_libraries(dhttpd curl)

add_subdirectory(tests)

