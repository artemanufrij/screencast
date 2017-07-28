project (com.github.artemanufrij.screencast)
cmake_minimum_required (VERSION 2.8)
cmake_policy (VERSION 2.6)
include (GNUInstallDirs)
list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

set (DATADIR "${CMAKE_INSTALL_PREFIX}/share")
set (PKGDATADIR "${DATADIR}/eidete")
set (GETTEXT_PACKAGE ${CMAKE_PROJECT_NAME})
add_definitions(-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\" -DWNCK_I_KNOW_THIS_IS_UNSTABLE)


list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

configure_file (${CMAKE_SOURCE_DIR}/Config.vala.cmake ${CMAKE_BINARY_DIR}/src/Config.vala)


find_package(PkgConfig)
pkg_check_modules(DEPS REQUIRED gtk+-3.0>=3.10
    libwnck-3.0
    granite
    xtst
    gdk-x11-3.0
    x11
    gstreamer-1.0
    gstreamer-pbutils-1.0)

# Comment this out to enable C compiler warnings
add_definitions (-w)

add_definitions(${DEPS_CFLAGS})
link_libraries(${DEPS_LIBRARIES})
link_directories(${DEPS_LIBRARY_DIRS})

# Vala Stuff
include (ValaPrecompile)
find_package (Vala REQUIRED)
include (ValaVersion)
ensure_vala_version ("0.21.2" MINIMUM)

# Translation files
add_subdirectory (po)
add_subdirectory (data)
add_subdirectory (src)



