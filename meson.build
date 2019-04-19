project('com.github.artemanufrij.screencast', 'vala', 'c', version: '0.3.0')

i18n = import('i18n')

add_project_arguments(
    '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
    language: 'c'
)

subdir('src')

executable(
    meson.project_name(),
    sources,
    config_header,
    dependencies: [
        dependency('granite'),
        dependency('libwnck-3.0'),
        dependency('xtst'),
        dependency('gdk-x11-3.0'),
        dependency('x11'),
        dependency('gstreamer-1.0'),
        dependency('gstreamer-pbutils-1.0'),
        dependency('appindicator3-0.1'),
        dependency('gtk+-3.0')
    ],
    install: true
)

subdir('data')
subdir('po')
subdir('schemas')

meson.add_install_script('meson/post_install.py')