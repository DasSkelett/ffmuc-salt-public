#
# Configure locales
#

locales:
  pkg.installed

# Workaround missing locale.present in our salt version
/etc/locale.gen:
  file.managed:
    - source: salt://locales/locale.gen
    - require:
      - pkg: locales

locale-gen:
  cmd.run:
    - onchanges:
      - file: /etc/locale.gen

en_US.UTF-8:
  locale.system:
    - require:
      - file: /etc/locale.gen
