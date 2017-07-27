vala_precompile(VALA_C
    eidete.vala
    Widgets/countdown.vala
    Widgets/keyview.vala
    Widgets/selectionarea.vala
    Widgets/end_dialog.vala
    desktop_launcher.vala
    ${CMAKE_BINARY_DIR}/src/Config.vala
PACKAGES
    granite
    gtk+-3.0
    gstreamer-1.0
    gstreamer-pbutils-1.0
    libwnck-3.0
    gdk-x11-3.0
OPTIONS
    --enable-experimental
    --thread
    --vapidir=${CMAKE_BINARY_DIR}/vapi/
    )


add_executable (${CMAKE_PROJECT_NAME} ${VALA_C} keycapture.c)
install(TARGETS ${CMAKE_PROJECT_NAME} RUNTIME DESTINATION bin)
