# Check http://webdev.elementaryos.org/docs/developer-guide/cmake for documentation

project (eidete)
cmake_minimum_required (VERSION 2.8)
cmake_policy (VERSION 2.6)

list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake/vala)

#
# Base bits
#

enable_testing ()

set (DATADIR "${CMAKE_INSTALL_PREFIX}/share")
set (PKGDATADIR "${DATADIR}/eidete")
set (GETTEXT_PACKAGE "eidete")
set (RELEASE_NAME "Feature rich and functional.")
set (VERSION "0.2")
set (VERSION_INFO "Release")
set (CMAKE_C_FLAGS "-ggdb")
set (PREFIX ${CMAKE_INSTALL_PREFIX})
set (DOLLAR "$")

# Comment this out to enable C compiler warnings
add_definitions (-w)

list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

# Building for GStreamer 1.0 by default
# Uncomment the following line to build for GStreamer 0.10
# set (USE_GSTREAMER_0_10 "TRUE")

if(DEFINED USE_GSTREAMER_0_10) 
    message ("-- Building eidete for GStreamer 0.10")
    set(EXTRA_DEFINITIONS -DGSTREAMER_0_10_IS_DEFINED)
    add_definitions(${EXTRA_DEFINITIONS})
    set(GST_PACKAGES gstreamer-interfaces-0.10 gstreamer-0.10 gstreamer-pbutils-0.10)
else ()     
    message ("-- Building eidete for GStreamer 1.0")   
    set(GST_PACKAGES gstreamer-1.0 gstreamer-pbutils-1.0)
endif ()

configure_file (${CMAKE_SOURCE_DIR}/src/Config.vala.cmake ${CMAKE_BINARY_DIR}/src/Config.vala)
add_definitions(-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\" -DWNCK_I_KNOW_THIS_IS_UNSTABLE)

find_package(PkgConfig)
pkg_check_modules(DEPS REQUIRED gtk+-3.0>=3.10
    libwnck-3.0
    granite
    xtst
    gdk-x11-3.0
    x11
    ${GST_PACKAGES})

# TEST
add_definitions(${DEPS_CFLAGS})

link_libraries(${DEPS_LIBRARIES})
link_directories(${DEPS_LIBRARY_DIRS})

find_package(Vala REQUIRED)
include(ValaVersion)
ensure_vala_version("0.16.0" MINIMUM)

include(ValaPrecompile)

vala_precompile(VALA_C
    src/eidete.vala
    src/Widgets/countdown.vala
    src/Widgets/keyview.vala
    src/Widgets/selectionarea.vala
    src/Widgets/end_dialog.vala
    src/desktop_launcher.vala
    ${CMAKE_BINARY_DIR}/src/Config.vala
PACKAGES
    granite
    gtk+-3.0
    ${GST_PACKAGES}
    libwnck-3.0
    gdk-x11-3.0
OPTIONS
    --enable-experimental
    --thread
    --vapidir=${CMAKE_CURRENT_SOURCE_DIR}/vapi/
    ${EXTRA_DEFINITIONS}
    )

vala_precompile(VALA_C_VIDEOBIN
    src/videobin_uploader.vala
PACKAGES
    gtk+-3.0
    gio-2.0
    )

add_subdirectory (po)

add_executable(eidete ${VALA_C} src/keycapture.c)
add_executable(videobin-uploader ${VALA_C_VIDEOBIN})

install(TARGETS videobin-uploader RUNTIME DESTINATION bin)
install(TARGETS eidete RUNTIME DESTINATION bin)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/eidete.desktop DESTINATION share/applications)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/32/eidete.svg DESTINATION share/icons/hicolor/32x32/apps)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/48/eidete.svg DESTINATION share/icons/hicolor/48x48/apps)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/64/eidete.svg DESTINATION share/icons/hicolor/64x64/apps)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/128/eidete.svg DESTINATION share/icons/hicolor/128x128/apps)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/48/videobin.svg DESTINATION share/icons/hicolor/48x48/apps)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/videobin.contract DESTINATION ${CMAKE_INSTALL_PREFIX}/share/contractor)
