project('gfile', 'c',
  version : '0.1',
  default_options : ['buildtype=debugoptimized','warning_level=3','c_std=c99',])

glib_dep = dependency('glib-2.0')
gio_dep = dependency('gio-2.0')

executable('gfile',
           'gfile.c',
           dependencies : [glib_dep, gio_dep])
