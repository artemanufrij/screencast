conf_data = configuration_data()
conf_data.set_quoted('PKGDATADIR', join_paths(get_option('prefix'), get_option('datadir'), meson.project_name()))
config_header = configure_file(
    input: 'Config.vala.in',
    output: 'Config.vala',
    configuration: conf_data
)

sources = files(
    'Interfaces/MediaKeys.vala',
    'Widgets/Countdown.vala',
    'Widgets/KeyView.vala',
    'Widgets/SelectionArea.vala',
    'Application.vala',
    'MainWindow.vala',
    'Settings.vala',
    'keycapture.c'
)